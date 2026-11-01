# Release history — ORBIT ZERO

## v1.8 · GitHub Pages Multiplayer (web) — 2026-11-01
- Added playable touch-friendly browser edition under `web/` and GitHub Pages deploy workflow.
- Added default WebRTC 1v1 rooms through Trystero public signaling relays, six-character invite codes and shareable links.
- Added optional Firebase Realtime Database transport with private rooms and anonymous authentication.
- Recreated 40 sequentially locked missions, five Collections and five boss encounters in HTML5 Canvas.
- Added 360° pressure defense, computer points, duel attacks, endless mode, cosmetic hangar, Nordic UI and original compressed sci-fi audio.
- Provided local mobile UI tests and publishing instructions.

## v1.7 · Game Center Multiplayer (native iOS)
- Existing SwiftUI/SpriteKit/GameKit project is preserved under `ios/`.
- **Not** the same multiplayer protocol as the v1.8 web release; native Game Center does not cross-play with the web rooms.

## Validation notes
- JavaScript syntax checked with Node.js 22.
- Browser navigation, mission locks, responsive home menu and first full 360° pressure spawn tested with an isolated Chromium smoke test.
- GitHub Pages build has not been executed against a real repository.
- Live remote multiplayer has not been tested against two internet-connected devices.
