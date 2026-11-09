# NocturnalZone Codex Theme

NocturnalZone theme files for Codex.

![NocturnalZone Codex app screenshot](assets/screenshot-app.png)

![NocturnalZone Codex CLI screenshot](assets/screenshot-cli.png)

This repository provides two formats:

- `nocturnalzone-codex-theme.txt` for the Codex app appearance import
- `nocturnalzone.tmTheme` for Codex CLI syntax highlighting

The palette follows the shared NocturnalZone design tokens: absolute black background, restrained neutral text, blue/cyan structure colors, green literals, warm type and diff colors, and low-glare contrast for long coding sessions.

## Codex App

Use `nocturnalzone-codex-theme.txt` from the Codex app appearance settings.

1. Open Codex app settings.
2. Go to Appearance.
3. Use the theme import control.
4. Select `nocturnalzone-codex-theme.txt`.

The app theme file uses Codex's exported `codex-theme-v1:` format.

## Codex CLI

Install directly from GitHub:

```sh
mkdir -p ~/.codex/themes
curl -fsSL https://raw.githubusercontent.com/noxyzone/nocturnalzone-codex-theme/main/nocturnalzone.tmTheme \
  -o ~/.codex/themes/nocturnalzone.tmTheme
```

Or install from a local checkout:

```sh
mkdir -p ~/.codex/themes
cp nocturnalzone.tmTheme ~/.codex/themes/
```

Then open Codex CLI and run:

```text
/theme
```

Select `nocturnalzone`.

## Screenshots

`assets/screenshot-app.png` is captured from the Codex app:

```bash
scripts/screenshot-app.sh
```

The app theme must already be applied in the Codex app Appearance settings. The script sends a
prompt that produces a normal answer with one paragraph, three bullets, and a Markdown link, so
the accent color is visible, then captures the largest Codex window. Plain body text, an empty
new chat, the unfinished input field, and the `@` candidate menu are not valid subjects because
they do not show the accent color.

`assets/screenshot-cli.png` is captured from the Codex CLI `/theme` live preview:

```bash
scripts/screenshot-cli.sh
```

`nocturnalzone.tmTheme` must be installed for Codex CLI and `nocturnalzone` must already be
selected in its `/theme` screen. The script opens a new WezTerm window, starts Codex CLI there,
opens `/theme`, and captures only that new window. The capture subject is the live preview:
`Select Syntax Theme` and `nocturnalzone (custom) (current)` on the left, a Rust-style preview
diff on the right. A `git diff --no-index --color=always` card is not a substitute, and
`codex --no-alt-screen` is not used because it changes the drawing path.

Both scripts accept `--output-dir DIR` to capture outside `assets/`. macOS must allow the
terminal to control the computer (**System Settings > Privacy & Security > Accessibility**) so
the window geometry can be read.

## Workspace Install Script

In the NocturnalZone workspace, the shared installer also copies this theme:

```sh
/Users/noxy/nocturnalzone/scripts/theme-install.sh
```

That script installs the Zed, WezTerm, Xcode, and Codex CLI NocturnalZone themes into their local destinations.

## Files

| File                            | Purpose                  |
| ------------------------------- | ------------------------ |
| `nocturnalzone.tmTheme`         | Codex CLI TextMate theme |
| `Twilight.tmTheme`              | Twilight base reference  |
| `nocturnalzone-codex-theme.txt` | Codex app import theme   |

## Design

`nocturnalzone.tmTheme` keeps Twilight's broad TextMate scope coverage while replacing the palette with NocturnalZone colors.

Core syntax mapping:

| Scope group                          | Color     |
| ------------------------------------ | --------- |
| Background                           | `#000000` |
| Foreground                           | `#9d9da6` |
| Comments                             | `#787879` |
| Keywords, tags, links                | `#79c0dc` |
| Functions, support functions         | `#27b8c8` |
| Types, storage, CSS values           | `#d6c95f` |
| Strings                              | `#3fb085` |
| String escapes                       | `#5cbc98` |
| Regex strings                        | `#5bd2e0` |
| Constants, attributes, preprocessors | `#c47fd4` |
| Properties, entities, changed diff   | `#f4a823` |
| Deleted diff, errors                 | `#ff7a9e` |

## License

MIT License. See `LICENSE`.
