# App Store Connect · ORBIT ZERO v1.5

1. Opret appen på App Store Connect med det samme Bundle ID som i Xcode (`com.konhagengames.orbitzero`).
2. Gennemfør **Paid Apps Agreement**, bank- og skatteoplysninger.
3. Brug `APP_STORE_CONNECT_PRODUCTS.csv` som grundlag for produkt-ID'er. Opret hvert produkt med præcis samme ID som i kildekoden.
4. Virtuelle Sparks og hjælpepakkers køb er **Consumable**; permanente rumskibe og effekter er **Non-Consumable**.
5. Tilføj lokale produktnavne/beskrivelser, priser og de nødvendige skærmbilleder.
6. Test alle køb, afbrudte køb, tilbagekaldelser og gendannelse via StoreKit Testing / Sandbox.
7. Test på en fysisk iPhone, før appen sendes til godkendelse.

Bemærk: Koden har lokal registrering af købte consumables. For en kommerciel udgivelse bør du gennemgå transaktionslogik, eventuel serververificering og sikring mod duplikater. In-app purchases er ikke live blot fordi projektet er på GitHub.
