#!/usr/bin/env bash
set -euo pipefail

# NocturnalZone Codex CLIテーマのプレビュー画像（assets/screenshot-cli.png）を再生成する。
# 撮影用の新規WezTermウィンドウでCodex CLIを起動し、/themeのライブプレビューを撮る。
# 既存の作業中Codex CLIウィンドウには送信しない。

usage() {
    cat <<'USAGE'
Regenerate assets/screenshot-cli.png from the Codex CLI /theme live preview.

Usage:
  scripts/screenshot-cli.sh [options]

Options:
  -o, --output-dir DIR  Output directory for screenshot-cli.png. Default: assets/
  -h, --help            Show this help and exit.

Notes:
  - nocturnalzone.tmTheme must be installed for Codex CLI and `nocturnalzone`
    must already be selected in the CLI's /theme screen.
  - The Codex app is not captured by this script.
  - A new WezTerm window is opened with `open -na WezTerm`; text is sent to the
    new pane id via `wezterm cli send-text`, never to an existing working pane.
  - `codex --no-alt-screen` is not used: it changes the drawing path and the
    colors no longer match the real CLI.
  - The capture subject is the /theme live preview: `Select Syntax Theme` and
    `nocturnalzone (custom) (current)` on the left, a Rust-style preview diff
    with `-` and `+` line backgrounds on the right. A
    `git diff --no-index --color=always` card is not a substitute.
  - The window rect comes from CoreGraphics and the window is resized to
    1200x800; WezTerm quantizes the real rect by cell size, so the image is
    around 1200x791 (2400x1582 on Retina). The rect is never padded or scaled.
  - The capture window is left open after the run.
  - Window geometry comes from the Accessibility API, so the terminal must be
    allowed to control the computer (System Settings > Privacy & Security >
    Accessibility).

Environment:
  WEZTERM_WINDOW_TITLE_PREFIX  Prefix of the capture window title.
                               Default: nocturnalzone-codex-t
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

# 撮影用ウィンドウのサイズと位置。
window_width=1200
window_height=800
window_x=60
window_y=60

# WezTermのウィンドウタイトルは20文字に切り詰められるため、前方一致で判定する。
# 既定値は移植元の撮影手順で実際に観測された切り詰め済みタイトルの先頭部分に合わせる。
window_title_prefix="${WEZTERM_WINDOW_TITLE_PREFIX:-nocturnalzone-codex-t}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"
lib_dir="$script_dir/lib"

output_dir="$repo_root/assets"
process_name="WezTerm"
tab_title="NZ_CLI_SCREENSHOT"

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

command -v wezterm >/dev/null 2>&1 || die "wezterm not found"
command -v osascript >/dev/null 2>&1 || die "osascript not found"
command -v swift >/dev/null 2>&1 || die "swift not found"
command -v jq >/dev/null 2>&1 || die "jq not found"
[ -x /usr/sbin/screencapture ] || die "screencapture not found"
[ -f "$lib_dir/activate-app.applescript" ] || die "missing $lib_dir/activate-app.applescript"
[ -f "$lib_dir/wezterm-capture-window.applescript" ] || die "missing $lib_dir/wezterm-capture-window.applescript"
[ -f "$lib_dir/wezterm-window-ids.swift" ] || die "missing $lib_dir/wezterm-window-ids.swift"
[ -f "$lib_dir/wezterm-new-window-rect.swift" ] || die "missing $lib_dir/wezterm-new-window-rect.swift"

# 既存paneの一覧はwezterm muxが動いていないと取れないため、ここで前提を確認する。
wezterm cli list --format json >/dev/null 2>&1 ||
    die "wezterm cli is not available; start WezTerm first"

tmp_dir=""
pane_id=""

cleanup() {
    local status=$?
    # 成功時は撮影窓を残す仕様だが、失敗時は自分で開いたpane（Codex CLI）を閉じる。
    if [ "$status" -ne 0 ] && [ -n "$pane_id" ]; then
        wezterm cli kill-pane --pane-id "$pane_id" >/dev/null 2>&1 ||
            printf 'warning: could not close WezTerm pane %s\n' "$pane_id" >&2
    fi
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
shot="$tmp_dir/screenshot-cli.png"

before_json="$(wezterm cli list --format json)"
before_panes="$(printf '%s' "$before_json" | jq -r '.[].pane_id' | tr '\n' ' ')"
cg_before="$(swift "$lib_dir/wezterm-window-ids.swift" "$process_name")" # guardrail-allow: language-delegation

# --no-alt-screenは使わない。通常TUIの色をそのまま撮る。
# wezterm cli spawn --new-windowは使わない。open -naの新規ウィンドウを使う。
open -na "$process_name"

# 新規ウィンドウが作られてmuxがpaneを認識するまでのGUI待ち。
sleep 2

after_json="$(wezterm cli list --format json)"
pane_id=""
while IFS= read -r id; do
    [ -n "$id" ] || continue
    case " $before_panes " in
    *" $id "*) continue ;;
    esac
    pane_id="$id"
done < <(printf '%s' "$after_json" | jq -r '.[].pane_id')

[ -n "$pane_id" ] || die "new WezTerm pane not found; close extra WezTerm windows and retry"

wezterm cli set-tab-title --pane-id "$pane_id" "$tab_title"
# repoのpathは空白を含み得るため、送信前にシェルquotingする。
printf -v repo_quoted '%q' "$repo_root"
wezterm cli send-text --pane-id "$pane_id" "cd $repo_quoted && codex"
wezterm cli send-text --pane-id "$pane_id" --no-paste $'\r'

# Codex CLIの初期化待ち。初期化完了は到達確認できないため固定時間だけ待つ。
sleep 5
wezterm cli send-text --pane-id "$pane_id" "/theme"
wezterm cli send-text --pane-id "$pane_id" --no-paste $'\r'

# テーマ一覧とライブプレビューが描画されるまで待つ。
sleep 3
wezterm cli activate-pane --pane-id "$pane_id"
sleep 1

osascript "$lib_dir/activate-app.applescript" "$process_name" 1 >/dev/null # guardrail-allow: language-delegation

osascript "$lib_dir/wezterm-capture-window.applescript" "$process_name" "$window_title_prefix" "$window_width" "$window_height" "$window_x" "$window_y" >/dev/null # guardrail-allow: language-delegation

# リサイズ結果が画面へ反映されるまで待つ。
sleep 1

# window 1は使わない。既存作業ウィンドウを誤って動かすため。
# open -na前後のCoreGraphics window id差分から、新規WezTermウィンドウだけを撮る。
rect="$(CG_BEFORE="$cg_before" swift "$lib_dir/wezterm-new-window-rect.swift" "$process_name" "$window_title_prefix")" # guardrail-allow: language-delegation
case "$rect" in
[0-9]*,[0-9]*,[0-9]*,[0-9]*) ;;
*) die "no $process_name Codex CLI window rect found" ;;
esac

screencapture -R "$rect" "$shot"
[ -s "$shot" ] || die "screencapture did not write $shot"

mkdir -p "$output_dir"
cp "$shot" "$output_dir/screenshot-cli.png"

printf 'wrote %s (window rect %s, pane %s)\n' \
    "$(display_path "$output_dir/screenshot-cli.png")" "$rect" "$pane_id"
