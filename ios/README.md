# ORBIT ZERO v1.7 — Multiplayer Arena

**KONHAGEN GAMES** · Copenhagen · Native iPhone game (SwiftUI, SpriteKit, GameKit, StoreKit 2)

ORBIT ZERO is a minimalist Nordic sci-fi orbital action game. The v1.7 update adds Game Center peer-to-peer **Orbit Arena**, a real-time one-versus-one duel in addition to the existing single-player campaign.

## Highlights

- **40 campaign missions**, sequential unlocking across 5 Collections and 5 bosses.
- Computer Siege, adaptive bosses, pilot rank, daily challenges and endless mode.
- Premium Shop / Signature Hangar with StoreKit 2 integration; existing App Store Connect configuration required.
- Atmospheric original science-fiction sound effects and adaptive music.
- **New in v1.7:** Game Center sign-in, matchmaking, friend invites, peer-to-peer 1v1, live attack messages, 12-slot pressure meter and local duel rating.
- Full source in `OrbitZero.xcodeproj`; iOS 17+ (iPhone).

## Setup

1. Open `OrbitZero.xcodeproj` in Xcode on macOS.
2. Set your signing Team under `Signing & Capabilities`; verify **Game Center** is enabled for `com.konhagengames.orbitzero`.
3. Enable Game Center in App Store Connect and configure sandbox test users.
4. Run on **two iPhones** with different Game Center accounts. Open **Multiplayer** to find or invite an opponent.
5. For Shop purchases, configure the product IDs in `APP_STORE_CONNECT_PRODUCTS.csv`.

See [Multiplayer setup](docs/MULTIPLAYER_GAME_CENTER.md), [Danish README](README_DANSK.md) and [App Store setup](docs/APP_STORE_SETUP.md).

## Testing and status

Swift files parsed, Xcode project and entitlement file linted, and static multiplayer / mission unlock tests passed. **Actual Xcode compilation, two-device online play, Game Center sandbox, store purchases and connection resilience must be verified on macOS/iPhones before release.** Game Center peer-to-peer is not a cheat-resistant ranked backend; ratings are local and there is no global leaderboard yet.
