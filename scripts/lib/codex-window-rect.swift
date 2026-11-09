// Codexアプリのオンスクリーンウィンドウのうち、もっとも面積が大きいものの矩形を
// "x,y,width,height" で出力する。
// アクセシビリティAPIでは補助ウィンドウだけが見えることがあるため、CoreGraphicsの
// オンスクリーンウィンドウ一覧から選ぶ。
import CoreGraphics
import Foundation

struct WindowRect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    var area: Int {
        width * height
    }
}

let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
var best: WindowRect?

for window in windows {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    guard owner == "Codex",
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let x = bounds["X"] as? Int,
          let y = bounds["Y"] as? Int,
          let width = bounds["Width"] as? Int,
          let height = bounds["Height"] as? Int
    else { continue }

    let candidate = WindowRect(x: x, y: y, width: width, height: height)
    if candidate.area > (best?.area ?? -1) {
        best = candidate
    }
}

// CLIの結果として矩形だけをstdoutへ書き出す（print()は規約で禁止）。
if let window = best {
    FileHandle.standardOutput.write(Data("\(window.x),\(window.y),\(window.width),\(window.height)\n".utf8))
}
