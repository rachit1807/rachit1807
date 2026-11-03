import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".", isDirectory: true)
let assets = root.appendingPathComponent("assets", isDirectory: true)
let frames = 36

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
  NSColor(
    calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
    green: CGFloat((hex >> 8) & 0xff) / 255,
    blue: CGFloat(hex & 0xff) / 255,
    alpha: alpha
  )
}

func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat, tint: NSColor, mono: Bool = false, weight: NSFont.Weight = .regular) {
  let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
  (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: font, .foregroundColor: tint])
}

func render(_ width: Int, _ height: Int, _ draw: (CGContext, CGFloat) -> Void, frame: Int) -> CGImage {
  let image = NSImage(size: NSSize(width: width, height: height))
  image.lockFocusFlipped(true)
  guard let context = NSGraphicsContext.current?.cgContext else { fatalError("Could not create a drawing context") }
  let phase = CGFloat(frame) / CGFloat(frames) * .pi * 2
  draw(context, phase)
  image.unlockFocus()
  guard let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let cgImage = bitmap.cgImage else { fatalError("Could not render animation frame") }
  return cgImage
}

func makeGIF(_ name: String, width: Int, height: Int, draw: @escaping (CGContext, CGFloat) -> Void) {
  let url = assets.appendingPathComponent(name)
  guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames, nil) else {
    fatalError("Could not create GIF at \(url.path)")
  }
  CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0] as [CFString: Any]
  ] as CFDictionary)
  let frameProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.09] as [CFString: Any]
  ]
  for index in 0..<frames {
    CGImageDestinationAddImage(destination, render(width, height, draw, frame: index), frameProperties as CFDictionary)
  }
  guard CGImageDestinationFinalize(destination) else { fatalError("Could not finish GIF at \(url.path)") }
  print("Wrote \(url.path)")
}

func panel(_ context: CGContext, width: CGFloat, height: CGFloat, phase: CGFloat) {
  context.setFillColor(color(0x10070c).cgColor)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  context.setStrokeColor(color(0xe5b5c7, alpha: 0.055).cgColor)
  context.setLineWidth(1)
  for x in stride(from: 12, through: Int(width), by: 28) {
    context.move(to: CGPoint(x: CGFloat(x), y: 0)); context.addLine(to: CGPoint(x: CGFloat(x), y: height))
  }
  for y in stride(from: 12, through: Int(height), by: 24) {
    context.move(to: CGPoint(x: 0, y: CGFloat(y))); context.addLine(to: CGPoint(x: width, y: CGFloat(y)))
  }
  context.strokePath()
  let border = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: width - 2, height: height - 2), xRadius: 16, yRadius: 16)
  color(0x451126).setStroke(); border.lineWidth = 2; border.stroke()
  let scanX = (phase / (.pi * 2)) * (width + 90) - 45
  context.setFillColor(color(0xe5b5c7, alpha: 0.10).cgColor)
  context.fill(CGRect(x: scanX, y: 0, width: 28, height: height))
}

makeGIF("wave.gif", width: 44, height: 44) { context, phase in
  context.clear(CGRect(x: 0, y: 0, width: 44, height: 44))
  context.saveGState()
  context.translateBy(x: 22, y: 34)
  context.rotate(by: 0.30 * sin(phase))
  context.translateBy(x: -22, y: -34)
  let font = NSFont(name: "Apple Color Emoji", size: 34) ?? NSFont.systemFont(ofSize: 34)
  ("👋" as NSString).draw(at: NSPoint(x: 2, y: 3), withAttributes: [.font: font])
  context.restoreGState()
}

makeGIF("gradient-divider.gif", width: 900, height: 10) { context, phase in
  context.clear(CGRect(x: 0, y: 0, width: 900, height: 10))
  context.setFillColor(color(0x451126, alpha: 0.8).cgColor)
  context.fill(CGRect(x: 0, y: 3, width: 900, height: 4))
  let gradientColors: [CGColor] = [color(0xe5b5c7, alpha: 0).cgColor, color(0xf8f0f3, alpha: 0.95).cgColor, color(0xc77b9b, alpha: 0).cgColor]
  let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: gradientColors as CFArray,
    locations: [0, 0.5, 1]
  )!
  let x = (phase / (2 * .pi)) * 900
  for offset in [x, x - 900] {
    context.drawLinearGradient(gradient, start: CGPoint(x: offset - 100, y: 5), end: CGPoint(x: offset + 100, y: 5), options: [])
  }
}

// The profile README uses GIFs because GitHub does not animate embedded SVGs.
makeGIF("role-cycle.gif", width: 900, height: 90) { context, phase in
  panel(context, width: 900, height: 90, phase: phase)
  text("ROLE /", x: 28, y: 38, size: 13, tint: color(0x754b5b), mono: true, weight: .semibold)
  let roleIndex = Int((phase / (2 * .pi) * 3).rounded(.down)) % 3
  let roles = ["FULL-STACK DEVELOPER", "BACKEND & API BUILDER", "AI & DEVELOPER TOOLS"]
  text(roles[roleIndex], x: 138, y: 27, size: 25, tint: color(0xf8f0f3), weight: .bold)
  let markerX = 850 + 10 * sin(phase)
  let dot = NSBezierPath(ovalIn: NSRect(x: markerX - 6, y: 39 - 6 * sin(phase), width: 12, height: 12))
  color(0xe5b5c7, alpha: 0.55 + 0.45 * (0.5 + 0.5 * sin(phase))).setFill(); dot.fill()
}

makeGIF("focus-carousel.gif", width: 900, height: 230) { context, phase in
  panel(context, width: 900, height: 230, phase: phase)
  text("FOCUS AREAS  /  ROTATING READOUT", x: 30, y: 26, size: 13, tint: color(0xe5b5c7), mono: true, weight: .semibold)
  context.setStrokeColor(color(0x56303f).cgColor); context.move(to: CGPoint(x: 25, y: 54)); context.addLine(to: CGPoint(x: 875, y: 54)); context.strokePath()
  let index = Int((phase / (2 * .pi) * 3).rounded(.down)) % 3
  let titles = ["FULL-STACK PRODUCTS", "BACKEND SYSTEMS", "AI & DEVELOPER TOOLS"]
  let captions = ["INTERFACE  →  API  →  DATA", "REST APIs  ·  SERVICES  ·  DATABASES", "MODEL-ASSISTED WORKFLOWS  ·  BUILD  ·  ITERATE"]
  text(titles[index], x: 36, y: 76, size: 30, tint: color(0xf8f0f3), weight: .bold)
  text(captions[index], x: 38, y: 121, size: 14, tint: color(0xc77b9b), mono: true)
  let barWidth: CGFloat = 820
  context.setFillColor(color(0x3b202b).cgColor); context.fill(CGRect(x: 38, y: 177, width: barWidth, height: 4))
  context.setFillColor(color(0xe5b5c7).cgColor); context.fill(CGRect(x: 38, y: 177, width: barWidth * (0.12 + 0.88 * (0.5 + 0.5 * sin(phase))), height: 4))
  let dot = NSBezierPath(ovalIn: NSRect(x: 852, y: 28, width: 8, height: 8)); color(0xe5b5c7, alpha: 0.4 + 0.6 * (0.5 + 0.5 * sin(phase))).setFill(); dot.fill()
}

makeGIF("tech-orbit.gif", width: 900, height: 360) { context, phase in
  panel(context, width: 900, height: 360, phase: phase)
  text("TECH ORBIT  /  STACK SIGNAL", x: 30, y: 22, size: 13, tint: color(0xe5b5c7), mono: true, weight: .semibold)
  let cx: CGFloat = 450, cy: CGFloat = 194
  for (rx, ry, alpha, rotation) in [(310.0, 103.0, 0.55, 0.0), (225.0, 75.0, 0.32, -0.35)] {
    let orbit = NSBezierPath(ovalIn: NSRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    color(0x754b5b, alpha: alpha).setStroke(); orbit.lineWidth = 1.5
    context.saveGState(); context.translateBy(x: cx, y: cy); context.rotate(by: rotation); context.translateBy(x: -cx, y: -cy); orbit.stroke(); context.restoreGState()
  }
  let pulse = 1 + 0.05 * sin(phase)
  let core = NSBezierPath(ovalIn: NSRect(x: cx - 52 * pulse, y: cy - 52 * pulse, width: 104 * pulse, height: 104 * pulse))
  color(0x21131b).setFill(); core.fill(); color(0xc77b9b).setStroke(); core.lineWidth = 2; core.stroke()
  text("SYSTEM", x: cx - 28, y: cy - 10, size: 12, tint: color(0xf8f0f3), mono: true, weight: .semibold)
  text("CORE", x: cx - 22, y: cy + 12, size: 12, tint: color(0xc77b9b), mono: true)
  let names = ["JS", "REACT", "PY", "NODE", "SQL", "GIT"]
  for (index, name) in names.enumerated() {
    let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
    let speed: CGFloat = 1 + CGFloat(index % 3) * 0.28
    let angle = phase * direction * speed + CGFloat(index) * (.pi / 3)
    let rx: CGFloat = index < 4 ? 300 : 215
    let ry: CGFloat = index < 4 ? 98 : 70
    let orbitRotation: CGFloat = index < 4 ? 0 : -0.35
    let rawX = rx * cos(angle), rawY = ry * sin(angle)
    let ox = rawX * cos(orbitRotation) - rawY * sin(orbitRotation)
    let oy = rawX * sin(orbitRotation) + rawY * cos(orbitRotation)
    let x = cx + ox, y = cy + oy
    let radius: CGFloat = name == "REACT" || name == "NODE" ? 28 : 24
    let badge = NSBezierPath(ovalIn: NSRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
    color(0x21131b).setFill(); badge.fill(); color(0xe5b5c7).setStroke(); badge.lineWidth = 1.5; badge.stroke()
    let width = (name as NSString).size(withAttributes: [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)]).width
    text(name, x: x - width / 2, y: y - 7, size: 12, tint: color(0xf8f0f3), mono: true, weight: .bold)
  }
  text("JAVASCRIPT  ·  REACT  ·  PYTHON  ·  NODE.JS  ·  FASTAPI  ·  POSTGRESQL  ·  MONGODB  ·  DOCKER", x: 72, y: 330, size: 10, tint: color(0x754b5b), mono: true)
}

// Floating portrait and pointing pose use matching continuous bob and lean loops.
guard let portrait = NSImage(contentsOf: assets.appendingPathComponent("rachit-character-portrait.png")),
      let footer = NSImage(contentsOf: assets.appendingPathComponent("rachit-character-footer.png")) else {
  fatalError("Character source PNGs must exist in assets/")
}

makeGIF("rachit-character-portrait.gif", width: 600, height: 420) { context, phase in
  panel(context, width: 600, height: 420, phase: phase)
  let cx: CGFloat = 268, cy: CGFloat = 218 + 7 * sin(phase)
  let halo = NSBezierPath(ovalIn: NSRect(x: cx - 165, y: cy - 174, width: 330, height: 330))
  color(0x451126, alpha: 0.45 + 0.15 * sin(phase)).setFill(); halo.fill()
  let ring = NSBezierPath(ovalIn: NSRect(x: cx - 163, y: cy - 172, width: 326, height: 326))
  color(0xc77b9b, alpha: 0.55).setStroke(); ring.lineWidth = 2; ring.stroke()
  context.saveGState(); context.translateBy(x: cx, y: cy); context.scaleBy(x: 1, y: -1); context.rotate(by: 0.012 * sin(phase)); context.translateBy(x: -cx, y: -cy)
  portrait.draw(in: NSRect(x: cx - 162, y: cy - 168, width: 324, height: 336), from: .zero, operation: .sourceOver, fraction: 1)
  context.restoreGState()
  text("ID / RT-1807", x: 414, y: 35, size: 11, tint: color(0xc77b9b), mono: true)
  let signal = NSBezierPath(ovalIn: NSRect(x: 560, y: 35, width: 7, height: 7)); color(0xe5b5c7, alpha: 0.45 + 0.55 * (0.5 + 0.5 * sin(phase))).setFill(); signal.fill()
}

makeGIF("rachit-character-footer.gif", width: 420, height: 520) { context, phase in
  panel(context, width: 420, height: 520, phase: phase)
  let centerX: CGFloat = 178, centerY: CGFloat = 260 + 6 * sin(phase)
  let glow = NSBezierPath(ovalIn: NSRect(x: 22, y: 24 + 4 * sin(phase), width: 330, height: 470))
  color(0x451126, alpha: 0.48).setFill(); glow.fill()
  context.saveGState(); context.translateBy(x: centerX, y: centerY); context.scaleBy(x: 1, y: -1); context.rotate(by: 0.008 * sin(phase)); context.translateBy(x: -centerX, y: -centerY)
  footer.draw(in: NSRect(x: 0, y: 18, width: 355, height: 494), from: .zero, operation: .sourceOver, fraction: 1)
  context.restoreGState()
  let spark = NSBezierPath(ovalIn: NSRect(x: 310 + 12 * sin(phase), y: 94 + 10 * cos(phase), width: 10, height: 10))
  color(0xf8f0f3, alpha: 0.45 + 0.55 * (0.5 + 0.5 * sin(phase))).setFill(); spark.fill()
}

makeGIF("identity-dashboard.gif", width: 900, height: 260) { context, phase in
  panel(context, width: 900, height: 260, phase: phase)
  text("IDENTITY / ENGINEERING", x: 38, y: 25, size: 12, tint: color(0xe5b5c7), mono: true, weight: .semibold)
  let cx: CGFloat = 112, cy: CGFloat = 141
  let outer = NSBezierPath(ovalIn: NSRect(x: cx - 56, y: cy - 56, width: 112, height: 112)); color(0x21131b).setFill(); outer.fill(); color(0xc77b9b).setStroke(); outer.lineWidth = 2; outer.stroke()
  let orbit = NSBezierPath(ovalIn: NSRect(x: cx - 44, y: cy - 44, width: 88, height: 88)); color(0xe5b5c7, alpha: 0.7).setStroke(); orbit.lineWidth = 1.5; orbit.setLineDash([3, 5], count: 2, phase: 0); orbit.stroke()
  let dot = NSBezierPath(ovalIn: NSRect(x: cx + 34 * cos(phase), y: cy + 34 * sin(phase) - 5, width: 10, height: 10)); color(0xf8f0f3).setFill(); dot.fill()
  text("RT", x: cx - 18, y: cy - 17, size: 30, tint: color(0xf8f0f3), weight: .bold)
  text("Rachit Tripathi", x: 198, y: 89, size: 28, tint: color(0xf8f0f3), weight: .bold)
  text("B.TECH IT STUDENT  /  ASPIRING SOFTWARE DEVELOPER", x: 200, y: 126, size: 12, tint: color(0xc77b9b), mono: true)
  text("Lucknow, India  ·  Full-stack apps  ·  Backend APIs  ·  AI/ML", x: 200, y: 158, size: 13, tint: color(0xd9c4ce))
  context.setStrokeColor(color(0x451126).cgColor); context.move(to: CGPoint(x: 200, y: 192)); context.addLine(to: CGPoint(x: 850, y: 192)); context.strokePath()
  let shineX = 200 + (phase / (2 * .pi)) * 650
  context.setFillColor(color(0xe5b5c7, alpha: 0.35).cgColor); context.fill(CGRect(x: shineX, y: 190, width: 34, height: 3))
  text("DESIGN  →  BUILD  →  REVIEW  →  ITERATE", x: 200, y: 211, size: 11, tint: color(0x754b5b), mono: true)
  text("ID / RT-1807", x: 780, y: 25, size: 10, tint: color(0x754b5b), mono: true)
}
