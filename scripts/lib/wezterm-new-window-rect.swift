// 撮影用に新しく増えたWezTermウィンドウの矩形を "x,y,width,height" で出力する。
// 既存の作業中Codex CLIウィンドウを誤って撮らないよう、CG_BEFOREのwindow idに含まれない
// ウィンドウだけを対象にする。
// 使い方: CG_BEFORE="<改行区切りのwindow id>" swift wezterm-new-window-rect.swift <owner> <title-prefix>
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(
        Data("usage: wezterm-new-window-rect.swift <owner> <title-prefix>\n".utf8)
    )
    exit(2)
}

let ownerName = args[1]
let titlePrefix = args[2]

/// 新規ウィンドウのタイトルはWezTerm側で20文字に切り詰められるため、
/// 切り詰め位置に依存しないよう前方一致で判定する。
let before = Set(
    (ProcessInfo.processInfo.environment["CG_BEFORE"] ?? "")
        .split(separator: "\n")
        .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
)

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
    let name = window[kCGWindowName as String] as? String ?? ""
    guard owner == ownerName,
          let id = window[kCGWindowNumber as String] as? Int,
          !before.contains(id),
          name.hasPrefix(titlePrefix),
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
