// 指定ownerのオンスクリーンウィンドウのCGWindowIDを1行ずつ出力する。
// 撮影前に記録し、撮影後に増えたウィンドウだけを対象にするために使う。
// 使い方: swift wezterm-window-ids.swift <owner>
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: wezterm-window-ids.swift <owner>\n".utf8))
    exit(2)
}

let ownerName = args[1]

let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

for window in windows {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    guard owner == ownerName,
          let id = window[kCGWindowNumber as String] as? Int
    else { continue }
    // CLIの結果としてidだけをstdoutへ書き出す（print()は規約で禁止）。
    FileHandle.standardOutput.write(Data("\(id)\n".utf8))
}
