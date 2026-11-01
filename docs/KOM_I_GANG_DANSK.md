# Sådan spiller I ORBIT ZERO fra hver jeres adresse

**Version 1.8 (web) · KONHAGEN GAMES**

GitHub Pages er en hjemmeside, ikke en iPhone-app. For at spille online skal du udgive webspillet. Multiplayer bruger som standard en direkte browserforbindelse (WebRTC) med offentlig signalering, så du ikke behøver oprette en Firebase-konto for at prøve.

## GitHub

1. Opret et nyt repo på https://github.com/new
2. Pak ZIP-filen ud og upload **filerne og mapperne** (ikke kun ZIP-filen).
3. Gå til **Settings → Pages → Source → GitHub Actions**.
4. Vent på at GitHub Actions-workflowen får en grøn status. Brug adressen i Pages-indstillingerne.

## Firebase (valgfrit alternativ, hvis direkte forbindelse driller)

1. Opret et Firebase-projekt på https://console.firebase.google.com/
2. Tilføj en webapp; kopier de fem felter til `web/firebase-config.js`.
3. Aktivér **Anonymous** under Authentication.
4. Opret en Realtime Database og indlæs `database.rules.json` under Rules.
5. Kontrollér Authentication → Authorized domains for `DIT-NAVN.github.io`.
6. Upload/commit konfigurationen igen, så GitHub Pages opdateres.

## Invitér din ven (uden ekstra opsætning)

1. Du åbner **Online Duel → Opret privat kamp**.
2. Vælg **Kopiér invitationslink** og send linket til din kammerat.
3. Han åbner linket og vælger **Deltag**.
4. Du trykker **Start duel**. I kan nu spille hjemmefra hver jeres sted.

## Forskellen på iPhone-appen og hjemmesiden

`ios/` indeholder Swift-projektet fra v1.7; `web/` er browserudgaven v1.8. De to udgaver spiller **ikke** mod hinanden på tværs. Begge skal bruge web-linket for at spille Online Duel via GitHub Pages.

Den almindelige kampagne virker uden Firebase. Webbutikken viser kosmetiske oplåsninger, men **ingen rigtige Apple-køb**.

## Hvad hvis I ikke kan finde hinanden?

WebRTC kan være blokeret på visse mobilnet og skolenet, og offentlige relæer kan være ustabile. Prøv et andet netværk eller konfigurér Firebase-alternativet fra README.md. Med Firebase udveksles kampstatus via databasen, så der ikke kræves en direkte WebRTC-forbindelse. Vennerne skal åbne GitHub Pages-webversionen, ikke den native iOS-app.
