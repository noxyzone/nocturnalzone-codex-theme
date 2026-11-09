-- 撮影用に開いた小さいWezTermウィンドウだけをAXRaiseして指定サイズへ寄せる。
-- 既存の作業中Codex CLIウィンドウを動かさないため、window 1は使わない。
-- 使い方: osascript wezterm-capture-window.applescript <process> <title-prefix> <width> <height> <x> <y>
on run argv
	set processName to item 1 of argv
	set targetName to item 2 of argv
	set targetWidth to (item 3 of argv) as integer
	set targetHeight to (item 4 of argv) as integer
	set targetX to (item 5 of argv) as integer
	set targetY to (item 6 of argv) as integer

	tell application "System Events" to tell process processName
		set targetWindow to missing value
		repeat with w in windows
			set n to name of w as text
			set s to size of w
			if n starts with targetName and (item 1 of s) < 1000 and (item 2 of s) < 700 then
				set targetWindow to w
				exit repeat
			end if
		end repeat

		if targetWindow is missing value then
			error "capture window not found: " & targetName
		end if

		perform action "AXRaise" of targetWindow
		set size of targetWindow to {targetWidth, targetHeight}
		set position of targetWindow to {targetX, targetY}
	end tell

	return ""
end run
