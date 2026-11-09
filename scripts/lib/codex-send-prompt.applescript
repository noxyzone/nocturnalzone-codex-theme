-- Codexアプリを前面化し、新規チャットへプロンプトを貼り付けて送信する。
-- 使い方: osascript codex-send-prompt.applescript <prompt>
-- クリップボードの内容はプロンプトで上書きされる。
on run argv
	set promptText to item 1 of argv

	tell application "Codex"
		activate
	end tell

	delay 1

	-- 別アプリへキー入力やReturnを送らないよう、前面がCodexであることを確かめる。
	tell application "System Events"
		set frontName to name of first application process whose frontmost is true
	end tell
	if frontName is not "Codex" then error "Codex is not frontmost: " & frontName

	-- 利用者のクリップボードを退避し、送信後に戻す（テキスト以外は戻せない場合がある）。
	set savedClipboard to missing value
	try
		set savedClipboard to the clipboard
	end try
	set the clipboard to promptText

	tell application "System Events"
		key code 53
		delay 0.2
		keystroke "n" using {command down}
		delay 1
		keystroke "v" using {command down}
		delay 0.3
		key code 36
	end tell

	delay 0.5
	if savedClipboard is not missing value then
		try
			set the clipboard to savedClipboard
		end try
	end if

	return ""
end run
