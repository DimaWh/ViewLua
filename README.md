# Player View (Severe)

Lightweight **spectate** script for [Severe](https://v-severe.gitbook.io/landing/introduction/readme.md). Uses `Camera.CameraSubject` (same idea as the Severe Admin Panel `view` command) — no freecam, low CPU, stable on external.

## Controls

| Key | Action |
|-----|--------|
| **V** | View the selected player (press **V** again to stop) |
| **P** | Move selection up the list |
| **;** | Move selection down the list |

## HUD

Green text on the left (same style as before):

- `>` marks the selected player
- `*` marks who you are currently viewing
- List scrolls when there are many players

## Usage

1. Join a Roblox game.
2. Paste `FreeCam.lua` into Severe → **Execute**.
3. Click the **Roblox** window.
4. Use **P** / **;** to pick a player, **V** to spectate.

## Notes

- You cannot view yourself (skipped in the list).
- If the target leaves or respawns without a character, view stops automatically.
- `Probe.lua` is optional (drawing API test only).
