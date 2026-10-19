import AppKit
import ImageIO
import UniformTypeIdentifiers

let width = 900
let height = 210
let frames = 24
let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "assets/engineering-hud.gif")

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
  NSColor(
    calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
    green: CGFloat((hex >> 8) & 0xff) / 255,
    blue: CGFloat(hex & 0xff) / 255,
    alpha: alpha
  )
}

func drawText(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, tint: NSColor, font: NSFont) {
  (text as NSString).draw(
    at: NSPoint(x: x, y: y),
    withAttributes: [.font: font.withSize(size), .foregroundColor: tint]
  )
}

func render(_ frame: Int) -> CGImage {
  let image = NSImage(size: NSSize(width: width, height: height))
  image.lockFocusFlipped(true)
  guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Could not create drawing context")
  }

  let ink = color(0x10070c)
  let rose = color(0xe5b5c7)
  let pink = color(0xc77b9b)
  let dim = color(0x754b5b)
  let phase = CGFloat(frame) / CGFloat(frames) * .pi * 2

  context.setFillColor(ink.cgColor)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))

  // Fine technical grid and panel rails.
  context.setStrokeColor(color(0xe5b5c7, alpha: 0.07).cgColor)
  context.setLineWidth(1)
  for x in stride(from: 16, through: width, by: 30) {
    context.move(to: CGPoint(x: x, y: 0))
    context.addLine(to: CGPoint(x: x, y: height))
  }
  for y in stride(from: 14, through: height, by: 24) {
    context.move(to: CGPoint(x: 0, y: y))
    context.addLine(to: CGPoint(x: width, y: y))
  }
  context.strokePath()

  let border = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: width - 2, height: height - 2), xRadius: 12, yRadius: 12)
  color(0x451126).setStroke()
  border.lineWidth = 2
  border.stroke()

  // Left identity panel.
  drawText("RACHIT  /  ENGINEERING PROFILE", x: 28, y: 28, size: 11, tint: rose, font: .monospacedSystemFont(ofSize: 11, weight: .semibold))
  drawText("FULL-STACK", x: 28, y: 66, size: 31, tint: color(0xf8f0f3), font: .systemFont(ofSize: 31, weight: .bold))
  drawText("AI  ·  BACKEND  ·  WEB SYSTEMS", x: 30, y: 92, size: 12, tint: pink, font: .monospacedSystemFont(ofSize: 12, weight: .medium))
  drawText("DESIGN  →  BUILD  →  SHIP", x: 30, y: 157, size: 10, tint: dim, font: .monospacedSystemFont(ofSize: 10, weight: .medium))

  // Animated scan sweep across the telemetry panel.
  let scanX = CGFloat(28 + (frame * 19) % 395)
  let scan = NSBezierPath(roundedRect: NSRect(x: scanX, y: 18, width: 2, height: 174), xRadius: 1, yRadius: 1)
  color(0xe5b5c7, alpha: 0.18).setFill()
  scan.fill()

  // Original reactor-inspired instrument dial; no borrowed logos or artwork.
  let cx: CGFloat = 492
  let cy: CGFloat = 105
  let pulse = 1 + 0.035 * sin(phase)
  for (radius, alpha, lineWidth) in [(58.0, 0.5, 1.2), (46.0, 0.8, 1.4), (31.0, 0.55, 1.0)] {
    let circle = NSBezierPath(ovalIn: NSRect(x: cx - radius * pulse, y: cy - radius * pulse, width: radius * 2 * pulse, height: radius * 2 * pulse))
    color(0xe5b5c7, alpha: alpha).setStroke()
    circle.lineWidth = lineWidth
    circle.stroke()
  }
  let tick = NSBezierPath()
  for index in 0..<36 {
    let angle = CGFloat(index) * .pi / 18
    let outer: CGFloat = index.isMultiple(of: 3) ? 66 : 62
    tick.move(to: CGPoint(x: cx + cos(angle) * outer, y: cy + sin(angle) * outer))
    tick.line(to: CGPoint(x: cx + cos(angle) * 70, y: cy + sin(angle) * 70))
  }
  color(0xc77b9b, alpha: 0.7).setStroke()
  tick.lineWidth = 1
  tick.stroke()

  let sweepAngle = phase
  let sweep = NSBezierPath()
  sweep.move(to: CGPoint(x: cx, y: cy))
  sweep.line(to: CGPoint(x: cx + cos(sweepAngle) * 57, y: cy + sin(sweepAngle) * 57))
  color(0xe5b5c7, alpha: 0.8).setStroke()
  sweep.lineWidth = 2
  sweep.stroke()
  let core = NSBezierPath(ovalIn: NSRect(x: cx - 9 * pulse, y: cy - 9 * pulse, width: 18 * pulse, height: 18 * pulse))
  color(0xe5b5c7, alpha: 0.16 + 0.12 * sin(phase)).setFill()
  core.fill()
  color(0xe5b5c7).setStroke()
  core.lineWidth = 1.5
  core.stroke()

  // Right-side capability readout.
  let readoutX: CGFloat = 602
  drawText("SYSTEMS  /  READY", x: readoutX, y: 28, size: 10, tint: rose, font: .monospacedSystemFont(ofSize: 10, weight: .semibold))
  let labels = ["REACT UI", "REST APIs", "DATA LAYER", "AUTOMATION"]
  for (index, label) in labels.enumerated() {
    let y = CGFloat(58 + index * 32)
    drawText(label, x: readoutX, y: y, size: 10, tint: color(0xeedfe5), font: .monospacedSystemFont(ofSize: 10, weight: .medium))
    let barWidth: CGFloat = 168
    let track = NSBezierPath(roundedRect: NSRect(x: readoutX, y: y + 15, width: barWidth, height: 3), xRadius: 2, yRadius: 2)
    color(0x3b202b).setFill()
    track.fill()
    let length = barWidth * (0.35 + 0.58 * (0.5 + 0.5 * sin(phase + CGFloat(index) * 1.2)))
    let bar = NSBezierPath(roundedRect: NSRect(x: readoutX, y: y + 15, width: length, height: 3), xRadius: 2, yRadius: 2)
    color(index.isMultiple(of: 2) ? 0xe5b5c7 : 0xc77b9b).setFill()
    bar.fill()
  }

  // Animated status lights and footer telemetry.
  for index in 0..<3 {
    let alpha = 0.35 + 0.65 * (0.5 + 0.5 * sin(phase + CGFloat(index) * 2))
    let dot = NSBezierPath(ovalIn: NSRect(x: CGFloat(816 + index * 20), y: 27, width: 6, height: 6))
    color(0xe5b5c7, alpha: alpha).setFill()
    dot.fill()
  }
  drawText("RT-1807  /  LIVE TELEMETRY", x: 602, y: 184, size: 9, tint: dim, font: .monospacedSystemFont(ofSize: 9, weight: .medium))

  image.unlockFocus()
  guard let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let cgImage = bitmap.cgImage else {
    fatalError("Could not render frame")
  }
  return cgImage
}

let properties: [CFString: Any] = [
  kCGImagePropertyGIFDictionary: [
    kCGImagePropertyGIFLoopCount: 0,
    kCGImagePropertyGIFDelayTime: 0.10,
  ] as [CFString: Any],
]
guard let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, frames, nil) else {
  fatalError("Could not create GIF output at \(output.path)")
}
for frame in 0..<frames {
  CGImageDestinationAddImage(destination, render(frame), properties as CFDictionary)
}
guard CGImageDestinationFinalize(destination) else {
  fatalError("Could not finish GIF output")
}
print("Wrote \(output.path)")
