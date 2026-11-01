# Changelog

## 1.6 (Build 9)
- Evolving Orbit with alternating gates and gravity rifts.
- Pilot ranks and persistent XP earned by skill.
- Adaptive bosses with three visible phases.
- Delayed cinematic victory with readable animations.
- Saved progress, brand and purchasing infrastructure preserved.

## v1.5 · Xcode Initialization Fix (build 8)

- Fixed Swift compiler error: `self` used in property access `unlockedMission` before all stored properties are initialized.
- Use a local `verifiedUnlock` during initialization to preserve sequential mission locks and stored progress.
- Kept v1.5, `com.konhagengames.orbitzero`, cosmetics, 40 missions, the shop, and space audio intact.
- Enhanced manual GitHub Action to run an actual iOS Simulator build, rather than syntax-only parsing.

## v1.5 · Sequential Mission Unlocks (build 7)

- Mission N+1 unlocks only after completing mission N (at least one star).
- All five Collections are locked until their preceding boss has been defeated.
- Access checks enforce locks even for programmatic navigation or direct mission starts.
- Existing legitimate progress is restored from consecutively completed mission stars.
- Removed Debug unlock-all shortcut; added clear locked-state UI and descriptions.
- Kept app version 1.5, Bundle ID, soundtracks, purchases, cosmetics, and gameplay unchanged.

## v1.5 · Space Audio Update (build 6)

- Two original cinematic loopable space soundtracks for orbit and boss encounters.
- Twelve newly synthesized spaceship, warp, laser, alert and victory effects.
- Adaptive music when bosses spawn or computer threat increases.
- Separate controls for **Space soundtrack** and **Sound effects**.
- Original procedural audio assets; no sampled third-party or film themes.
- Maintains version **1.5**, brand **KONHAGEN GAMES**, gameplay and existing save keys.

# Ændringslog

## 1.5 — 2026-11-01

- KONHAGEN GAMES-branding og iOS-version sat til 1.5 (build 5).
- Kompakt, skandinavisk startmenu med en synlig **Shop**-indgang.
- Shop og Signature Hangar organiseret i separate faner.
- 40 missioner på tværs af fem Collections og fem bosser.
- Computer Siege: computerens farepunkter, trusselsmåler og missionsforsvar.
- Daily Challenge, Endless Mode, masteries, stjerner og power-ups.
- Kosmetiske rumskibe og effekter med StoreKit 2-produkt-ID'er.

> Release-status: Kildepakke til Xcode; ikke en App Store-godkendt release.

## v1.7 — Build 10 — Multiplayer Arena

- Added Apple Game Center sign-in and matchmaker / friend invitations.
- Added online 1v1 Orbit Duel with reliable peer-to-peer packets and disconnect handling.
- Added independent 90-second PvP game mode: two threat points each lap, additional attacks for PERFECT gates, pressure and shield win conditions.
- Added stable Arena lobby and separate HUD, local duel rating/win-loss stats.
- Retained v1.6 campaign, locked missions, shop, cosmetics and music.
- Added Game Center entitlement and setup guide; no global leaderboard or authoritative competitive backend yet.
