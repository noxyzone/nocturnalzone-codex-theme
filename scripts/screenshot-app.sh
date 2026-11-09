#!/usr/bin/env bash
set -euo pipefail

# NocturnalZone Codexアプリテーマのプレビュー画像（assets/screenshot-app.png）を再生成する。
# CodexアプリでMarkdownリンクを含む通常回答を作り、最大面積のCodexウィンドウを撮影する。

usage() {
    cat <<'USAGE'
Regenerate assets/screenshot-app.png from a Codex app window.

Usage:
  scripts/screenshot-app.sh [options]

Options:
  -o, --output-dir DIR  Output directory for screenshot-app.png. Default: assets/
  -h, --help            Show this help and exit.

Notes:
  - nocturnalzone-codex-theme.txt must already be applied in the Codex app
    Appearance settings. Codex CLI and Terminal are not captured by this script.
  - The script sends this prompt to a new chat in the Codex app:
    "Create a short NocturnalZone app theme preview. Do not use a code block.
     Include one concise paragraph, three bullets, and a Markdown link labeled
     NocturnalZone Docs pointing to https://example.com."
    The sent answer must show a Markdown link in the accent color; plain body
    text, an empty new chat, or the unfinished input field is not acceptable.
  - The `@` candidate menu does not show the accent color and must not be the
    subject of the capture.
  - The clipboard is used to paste the prompt and restored afterwards (non-text
    clipboard contents may not be restorable). Keystrokes are sent only after
    confirming that the Codex app is frontmost.
  - The capture uses the Accessibility API to focus the app, so the terminal
    must be allowed to control the computer (System Settings > Privacy &
    Security > Accessibility).
USAGE
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

display_path() {
    local path="$1"
    case "$path" in
    "$repo_root"/*) printf '%s\n' "${path#"$repo_root"/}" ;;
    *) printf '%s\n' "$path" ;;
    esac
}

# アクセント色が出るMarkdownリンクを含む通常回答を作るためのプロンプト。
# コードブロックを使うとリンク色が確認できないため、本文・箇条書き・リンクだけを求める。
prompt="Create a short NocturnalZone app theme preview. Do not use a code block. Include one concise paragraph, three bullets, and a Markdown link labeled NocturnalZone Docs pointing to https://example.com."

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"
lib_dir="$script_dir/lib"

output_dir="$repo_root/assets"

while [ "$#" -gt 0 ]; do
    case "$1" in
    -o | --output-dir)
        [ "$#" -ge 2 ] || die "$1 requires a directory"
        output_dir="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        die "unknown argument: $1"
        ;;
    esac
done

command -v osascript >/dev/null 2>&1 || die "osascript not found"
command -v swift >/dev/null 2>&1 || die "swift not found"
[ -x /usr/sbin/screencapture ] || die "screencapture not found"
[ -f "$lib_dir/codex-send-prompt.applescript" ] || die "missing $lib_dir/codex-send-prompt.applescript"
[ -f "$lib_dir/codex-window-rect.swift" ] || die "missing $lib_dir/codex-window-rect.swift"

tmp_dir=""

cleanup() {
    local status=$?
    if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
        if [ -x /usr/bin/trash ]; then
            /usr/bin/trash "$tmp_dir" >/dev/null 2>&1 ||
                printf 'warning: could not move %s to Trash\n' "$tmp_dir" >&2
        else
            printf 'warning: /usr/bin/trash not found; leaving %s\n' "$tmp_dir" >&2
        fi
    fi
    return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

tmp_dir="$(mktemp -d)"
shot="$tmp_dir/screenshot-app.png"

osascript "$lib_dir/codex-send-prompt.applescript" "$prompt" >/dev/null # guardrail-allow: language-delegation

# 回答の生成と描画は外部要因で変動し、到達確認できる状態がないため固定時間だけ待つ。
sleep 25

# アクセシビリティAPIではなくCoreGraphicsの実矩形を使う。ウィンドウが1200x800に
# 揃っていればRetina環境では2400x1600前後になる。
rect="$(swift "$lib_dir/codex-window-rect.swift")" # guardrail-allow: language-delegation
case "$rect" in
[0-9]*,[0-9]*,[0-9]*,[0-9]*) ;;
*) die "could not read Codex window rect: '$rect'" ;;
esac

screencapture -R "$rect" "$shot"
[ -s "$shot" ] || die "screencapture did not write $shot"

mkdir -p "$output_dir"
cp "$shot" "$output_dir/screenshot-app.png"

printf 'wrote %s (window rect %s)\n' "$(display_path "$output_dir/screenshot-app.png")" "$rect"
