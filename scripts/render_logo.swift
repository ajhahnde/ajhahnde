#!/usr/bin/env swift
// Render the "ajhahnde" wordmark to a transparent PNG using the Orbitron font.
//
// Variants:
//   1: Regular  "ajhahnde"  (whole word, color1)
//   2: Bold     "ajhahnde"  (whole word, color1)
//   3: SemiBold "ajhahnde"  (whole word, color1)
//   4: split — "ajhahn" Regular color1 + "de" Bold color2  (the mark)
//
// Requires Orbitron-Regular.ttf, Orbitron-Bold.ttf, Orbitron-SemiBold.ttf
// in /Library/Fonts or ~/Library/Fonts.
//
// Reproduce the committed assets:
//   swift scripts/render_logo.swift 4 assets/ajhahnde_logo_light.png \
//        --color1 1B1F24 --color2 0B8FB8
//   swift scripts/render_logo.swift 4 assets/ajhahnde_logo_dark.png \
//        --color1 E8E8E8 --color2 5BC8F2
//
// For variant 4: --color1 styles "ajhahn", --color2 styles "de".
// For variants 1-3: --color1 styles the whole word; --color2 ignored.
// Default colors: black (000000).

import AppKit
import Foundation

func parseHexColor(_ hex: String) -> NSColor? {
    var h = hex
    if h.hasPrefix("#") { h.removeFirst() }
    guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
    let r = CGFloat((v >> 16) & 0xff) / 255.0
    let g = CGFloat((v >>  8) & 0xff) / 255.0
    let b = CGFloat( v        & 0xff) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}

let args = CommandLine.arguments
guard args.count >= 3, let variant = Int(args[1]) else {
    FileHandle.standardError.write(
        ("Usage: \(args[0]) <variant 1-4> <output.png> " +
         "[--font-size N] [--color1 RRGGBB] [--color2 RRGGBB]\n")
            .data(using: .utf8)!)
    exit(2)
}
let outputPath = args[2]

var fontSize: CGFloat = 500
var color1: NSColor = .black
var color2: NSColor = .black

var i = 3
while i < args.count {
    switch args[i] {
    case "--font-size":
        if i + 1 < args.count, let s = Double(args[i + 1]) {
            fontSize = CGFloat(s)
            i += 2
        } else { exit(2) }
    case "--color1":
        if i + 1 < args.count, let c = parseHexColor(args[i + 1]) {
            color1 = c
            i += 2
        } else { exit(2) }
    case "--color2":
        if i + 1 < args.count, let c = parseHexColor(args[i + 1]) {
            color2 = c
            i += 2
        } else { exit(2) }
    default:
        FileHandle.standardError.write("unknown arg: \(args[i])\n".data(using: .utf8)!)
        exit(2)
    }
}

func font(_ name: String, size: CGFloat) -> NSFont {
    guard let f = NSFont(name: name, size: size) else {
        FileHandle.standardError.write("Font \(name) not found\n".data(using: .utf8)!)
        exit(3)
    }
    return f
}

let regular  = font("Orbitron-Regular",  size: fontSize)
let bold     = font("Orbitron-Bold",     size: fontSize)
let semibold = font("Orbitron-SemiBold", size: fontSize)

let attrString: NSAttributedString
switch variant {
case 1:
    attrString = NSAttributedString(
        string: "ajhahnde",
        attributes: [.font: regular, .foregroundColor: color1])
case 2:
    attrString = NSAttributedString(
        string: "ajhahnde",
        attributes: [.font: bold, .foregroundColor: color1])
case 3:
    attrString = NSAttributedString(
        string: "ajhahnde",
        attributes: [.font: semibold, .foregroundColor: color1])
case 4:
    let s = NSMutableAttributedString()
    s.append(NSAttributedString(
        string: "ajhahn",
        attributes: [.font: regular, .foregroundColor: color1]))
    s.append(NSAttributedString(
        string: "de",
        attributes: [.font: bold, .foregroundColor: color2]))
    attrString = s
default:
    FileHandle.standardError.write("Variant must be 1-4\n".data(using: .utf8)!)
    exit(2)
}

let padding: CGFloat = fontSize * 0.15
let textSize = attrString.size()
let imageW = ceil(textSize.width + 2 * padding)
let imageH = ceil(textSize.height + 2 * padding)

let image = NSImage(size: NSSize(width: imageW, height: imageH))
image.lockFocus()
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: imageW, height: imageH).fill()
let drawY = (imageH - textSize.height) / 2
attrString.draw(at: NSPoint(x: padding, y: drawY))
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
else {
    FileHandle.standardError.write("Failed to encode PNG\n".data(using: .utf8)!)
    exit(4)
}

do {
    try png.write(to: URL(fileURLWithPath: outputPath))
    print("wrote \(outputPath) (\(Int(imageW))×\(Int(imageH)) px, variant \(variant))")
} catch {
    FileHandle.standardError.write("write failed: \(error)\n".data(using: .utf8)!)
    exit(5)
}
