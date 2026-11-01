# ORBIT ZERO 1.7 — Multiplayer Arena

**KONHAGEN GAMES** · iPhone · iOS 17+ · **Build 10**

Denne opdatering tilføjer **ægte 1-mod-1 multiplayer** med Apple Game Center til det eksisterende spil.

### Det nye

- **Multiplayer** i den kompakte hovedmenu, med en separat lobby.
- Apples Game Center-matchmaker kan finde en tilfældig modstander eller invitere venner.
- Begge spillere har hver sin orbit. Hver 360° omgang giver 2 røde farepunkter.
- PERFECТ gates sender 1 punkt til den anden spiller; hver tredje PERFECT i træk sender 2.
- Du skal fjerne de røde punkter og ramme din gate. Computerens trusselsmåler går til 12; du har 3 skjolde.
- Hver duel varer maksimalt 90 sekunder. Højeste score vinder ved tidens udløb.
- Duellrating og sejre/nederlag gemmes kun på den lokale iPhone – dette er endnu ikke en global rangliste.
- Alle de 40 missioner, 5 Collections, bosser, rumskibe, Shop, Hangar og originale musikspor er bevaret.

### Gør klar til Game Center

1. Åbn `OrbitZero.xcodeproj` i Xcode.
2. Vælg `OrbitZero` target > **Signing & Capabilities**. Vælg dit team og verificér Game Center. Entitlement-filen er med.
3. Aktivér Game Center for appens Bundle ID `com.konhagengames.orbitzero` i din Apple Developer-konto/App Store Connect.
4. Installer samme v1.7 på to iPhones og log ind på forskellige Game Center-konti.
5. Tryk **Multiplayer > Find or invite opponent** på iPhone.

Detaljer: `docs/MULTIPLAYER_GAME_CENTER.md`.

### Vigtig status

Swift-syntaks og projektfil er kontrolleret. Dette er ikke en færdig testet iPhone-build: Game Center-matchmaking og hele duellen skal verificeres i Xcode og på to iPhones. Der er endnu ingen 2v2, verdensrangliste eller serverbaseret anti-cheat.

Versionen er **1.7** efter brugerens versionsregel; næste ændring bliver **1.8**.
