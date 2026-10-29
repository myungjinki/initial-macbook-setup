// README 실행 화면(docs/screen.png) 만들기: TERM=dumb bash mac-setup.sh > /tmp/out.txt; swift docs/screen.swift /tmp/out.txt docs/screen.png
import AppKit
// 터미널처럼 칸(그리드)에 맞춰 그림: 한글·이모지 2칸, 나머지 1칸
let args = CommandLine.arguments
let lines = try! String(contentsOfFile: args[1], encoding: .utf8).trimmingCharacters(in: .newlines).components(separatedBy: "\n")
let font = NSFont(name: "Menlo", size: 15)!
let cw = ("M" as NSString).size(withAttributes: [.font: font]).width
let lh: CGFloat = 20
func cols(_ ch: Character) -> Int {
  let s = ch.unicodeScalars
  if s.contains(where: { $0.value == 0xFE0F }) || s.contains(where: { $0.value >= 0x1F000 }) { return 2 }
  if let v = s.first?.value, (0x1100...0x115F).contains(v) || (0x2E80...0xA4CF).contains(v) || (0xAC00...0xD7A3).contains(v) || (0xF900...0xFAFF).contains(v) || (0xFF00...0xFF60).contains(v) { return 2 }
  if let v = s.first?.value, [0x2705, 0x274C, 0x23F3, 0x2B1C, 0x2796].contains(v) { return 2 }
  return 1
}
let maxCols = lines.map { $0.reduce(0) { $0 + cols($1) } }.max()!
let pad: CGFloat = 24
let w = Int(ceil(CGFloat(maxCols) * cw + pad * 2)), h = Int(ceil(CGFloat(lines.count) * lh + pad * 2))
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w * 2, pixelsHigh: h * 2, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: w, height: h)
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
NSColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: w, height: h), xRadius: 10, yRadius: 10).fill()
let fg = NSColor(white: 0.92, alpha: 1), line = NSColor(white: 0.55, alpha: 1)
for (r, text) in lines.enumerated() {
  var col = 0
  let y = CGFloat(h) - pad - CGFloat(r + 1) * lh  // 이 줄 칸의 아래쪽
  for ch in text {
    let n = cols(ch), x = pad + CGFloat(col) * cw
    let box: [Character: (Bool, Bool, Bool, Bool)] = [  // 위 아래 왼 오른
      "─": (false, false, true, true), "│": (true, true, false, false), "┌": (false, true, false, true), "┐": (false, true, true, false),
      "└": (true, false, false, true), "┘": (true, false, true, false), "├": (true, true, false, true), "┤": (true, true, true, false),
      "┬": (false, true, true, true), "┴": (true, false, true, true), "┼": (true, true, true, true)]
    if let b = box[ch] {  // 선은 칸 끝까지 이어 그림
      line.setFill()
      let cx = x + cw / 2, cy = y + lh / 2, t: CGFloat = 1.2
      if b.0 { NSRect(x: cx - t/2, y: cy, width: t, height: lh / 2).fill() }
      if b.1 { NSRect(x: cx - t/2, y: y, width: t, height: lh / 2).fill() }
      if b.2 { NSRect(x: x, y: cy - t/2, width: cw / 2, height: t).fill() }
      if b.3 { NSRect(x: cx, y: cy - t/2, width: cw / 2, height: t).fill() }
    } else {
      let s = NSAttributedString(string: String(ch), attributes: [.font: font, .foregroundColor: fg])
      let sz = s.size()
      let scale = min(1, CGFloat(n) * cw / max(sz.width, 1))
      ctx.cgContext.saveGState()
      ctx.cgContext.translateBy(x: x + (CGFloat(n) * cw - sz.width * scale) / 2, y: y + (lh - sz.height * scale) / 2)
      ctx.cgContext.scaleBy(x: scale, y: scale)
      s.draw(at: .zero)
      ctx.cgContext.restoreGState()
    }
    col += n
  }
}
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
