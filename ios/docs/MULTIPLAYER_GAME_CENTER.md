# Multiplayer / Game Center — ORBIT ZERO 1.7

## Funktioner i denne kode

- Rigtig 1-mod-1 peer-to-peer multiplayer med Apple GameKit (`GKMatch`).
- Game Center login, Game Centers standard matchmaking og venne-invitationer.
- Separat Orbit Arena, så kampagne-missioner, Sparks, køb og skins ikke påvirker dueller.
- Lokal trusselsmåler: +2 punkter efter 360 grader; yderligere 1/2 punkter fra modstanderens PERFECT-træffere.
- Træk og interceptioner med samme én-fingers kontrol; tab ved 12 farepunkter eller 0 skjolde.
- Maksimal kampvarighed 90 sekunder. Ved udløb udveksles slutscore, og højeste score vinder.
- Lokal duellrating med +25 ved sejr og -15 ved nederlag (ikke Game Center ranked / ingen global rangliste endnu).
- Onlinetransport bruger versionsstyrede Codable-pakker med pålidelig levering og monoton sekvens.
- Forbindelsesfejl giver afbrudt kamp uden ratingsændring; app i baggrunden giver fortabt kamp.

## Krævet opsætning før du kan spille online

1. Åbn `OrbitZero.xcodeproj` i Xcode.
2. Vælg target `OrbitZero` -> `Signing & Capabilities` og verificér, at **Game Center** er aktiveret. Den tilhørende entitlements-fil følger med projektet. Hvis Xcode beder om opdatering af provisioning profile, så tillad automatisk signering.
3. Aktivér **Game Center** for appens eksisterende Bundle ID `com.konhagengames.orbitzero` i [App Store Connect](https://appstoreconnect.apple.com/) og udviklerkontoen, efter behov.
4. Log ind på Game Center med to forskellige testkonti på hver sin iPhone (eller relevante sandbox-konti).
5. Installér samme v1.7-build på begge enheder.
6. Åbn **Multiplayer** på begge enheder. Tryk **Find or invite opponent** og brug Apples matchmaking/invitation.
7. Test både sejre, nederlag, afbrudt netforbindelse, invitationer og fejlscenarier med begge enheder.

## Vigtige begrænsninger

- Online multiplayer er skrevet, men er **ikke** kørt eller end-to-end-testet på to iPhones i dette miljø.
- En global rangliste, 2v2 og servervalideret konkurrencerang er **ikke** implementeret.
- GameKit peer-to-peer er ikke en autoritativ anti-cheat-server. Lokal rating er kun til feedback; før rigtig konkurrenceliga kræves separat valideret backend og anti-cheat.
- Køb giver ingen fordel i Orbit Arena; kosmetiske genstande kan anvendes i kampagne som før.

## Fejlsøgning

- Game Center-knappen åbner ikke dialog: tjek om det eksisterende Bundle ID er aktiveret i App Store Connect og om signering er korrekt.
- Matcher aldrig: brug to forskellige Game Center-konti, ens build, stabilt netværk; tjek Game Center sandbox.
- Buildfejl ved entitlement: fjern og genaktivér Game Center capability via Xcode, så udviklerprofilen opdateres.
- Tests: `swiftc -frontend -parse OrbitZero/*.swift`, `python3 tools/test_v17_static.py`, og GitHub Actions iOS simulator-build.
