# ORBIT ZERO v1.8 — Web & iPhone

**KONHAGEN GAMES · Copenhagen**

This repository includes a playable HTML5 browser edition in [`web/`](web/) that can be hosted on **GitHub Pages** and the existing native **iOS v1.7** Swift / SpriteKit project in [`ios/`](ios/). Web v1.8 and native iOS v1.7 are distinct builds; the iPhone version has not yet been ported or updated to v1.8.

## Play in the browser (no installation)

After GitHub Pages has been enabled, open the link GitHub shows in **Settings → Pages**, typically `https://YOUR-USERNAME.github.io/REPOSITORY/`.

The browser edition includes:
- 40 sequentially unlocked missions across Aurora, Monolith, Equinox, Obsidian, and Zenith.
- Computer Siege: each orbit adds two threats; intercept them before the meter fills.
- Five boss missions, original sci-fi soundtracks, cosmetic hangar and endless mode.
- **Online Duel**: create a room, share a six-character code or invite URL, and play 1v1 from different locations (through direct WebRTC by default; Firebase is optional).
- Keyboard Space or one-touch controls. Mobile friendly.

**Note:** The web game reimplements the core game mechanics; it is not an iOS emulator. Progress and cosmetics are stored in the browser and do not automatically sync with the native iPhone application. Native StoreKit purchases do not run in a browser and are not available on GitHub Pages.

## 1. Publish to GitHub Pages

1. Create a GitHub repository (for example `orbit-zero`).
2. **Extract** this ZIP and upload its **contents**, preserving `.github/workflows/pages.yml` and the `web/` folder. Uploading the ZIP itself without extracting it will not create a playable site.
3. GitHub → **Settings → Pages → Build and deployment → Source: GitHub Actions**.
4. Push to the `main` branch. The included workflow publishes `web/` automatically.
5. Find the public URL in **Settings → Pages**. Send it to your friend.

On GitHub Free, GitHub Pages for this use normally requires a **public** repository. Do not commit personal secrets or signing credentials.

## 2. Online multiplayer: no additional account required by default

The default online transport uses **Trystero 0.26.0 + public Nostr signaling relays** to establish a browser-to-browser encrypted WebRTC data channel. You do **not** need to configure Firebase to try 1v1 with a friend: just publish GitHub Pages and send the invite URL. Both players need to leave the tab open. Some carrier/mobile networks or restrictive firewalls prevent direct WebRTC connections, and public relays do not have a guaranteed uptime. WebRTC peers can learn one another's IP addresses.

### Optional: Firebase transport for more reliable matchmaking

If direct P2P fails, configure Firebase. With the following five web settings present in `web/firebase-config.js`, the browser automatically switches to Firebase Realtime Database and anonymous authentication. Firebase is hosted infrastructure and may require billing depending on your use:

1. Visit [Firebase Console](https://console.firebase.google.com/) → create a project.
2. Add a **Web** app and copy its Firebase configuration.
3. Under **Build → Authentication → Sign-in method**, enable **Anonymous**.
4. Under **Build → Realtime Database**, create a database; choose a region. Open **Rules** and paste the contents of [`database.rules.json`](database.rules.json), then publish those rules. Do **not** use an open test-mode database for a public website.
5. Enter `apiKey`, `authDomain`, `databaseURL`, `projectId` and `appId` in [`web/firebase-config.js`](web/firebase-config.js). These Firebase web identifiers are designed to be public; **the database security rules provide access control**.
6. In Firebase Authentication → Settings → Authorized domains, add `YOUR-USERNAME.github.io` (if your deployment needs it). **Do not** enter a URL path here.
7. Commit the updated `web/firebase-config.js`. GitHub Pages redeploys. Both players open the same published URL. One creates a room; the other opens the invite link or enters the room code. When Firebase is configured, it is used instead of P2P.

Firebase usage can incur charges depending on your plan and traffic; monitor quotas. The game uses the real-time DB only for casual private rooms, with no globally verifiable ratings or anti-cheat server. Do not publish open Firebase database rules.

**Limitations of direct WebRTC:** Public relay availability is not guaranteed and some NAT/firewall combinations require TURN relay infrastructure. If your friend stays on "Waiting", try a different connection or enable Firebase fallback (Firebase solves signaling, but without a TURN relay cannot fix WebRTC limitations; Firebase transport does not use WebRTC).

## 3. Play a duel together

- Player A: **Online Duel → Opret privat kamp**.
- Share the invite link (e.g. `https://YOUR-USERNAME.github.io/REPOSITORY/?room=ABC234`).
- Player B: open the link, enter a nickname, press **Deltag**.
- Player A presses **Start duel**.
- Both sides play on their own screens. Completing two clean gates sends an attack. Each complete orbit adds two local threat points. Defend by hitting red targets; losing all shields or filling the threat meter ends the match.
- The match lasts up to 90 seconds. A disconnected player may lose after the reconnect window.

For remote play, **both users need a stable internet connection**. Try a laptop and mobile device with two distinct browsers to smoke-test before sharing.

## Local preview

From this repository directory:

```sh
python3 -m http.server 8000 --directory web
```

Open `http://localhost:8000` in a browser. Use HTTPS through GitHub Pages for your friend's phone and for secure features such as the invite clipboard. Direct P2P play requires internet and the signaling CDN/relays even on localhost. The campaign works without internet. Set Firebase web credentials only if you elect to use the alternative database-based transport.

## Source

- `web/` — HTML5 game, direct P2P transport and optional Firebase transport.
- `ios/` — previous native v1.7 iPhone project, with Game Center multiplayer (separate from browser duel rooms).
- `database.rules.json` — optional Firebase Realtime Database security rules. Paste this in Firebase Console only if using Firebase fallback.
- `.github/workflows/pages.yml` — auto-deploys the browser game on each push to `main`.
- `docs/` — additional guidance.

## Release notes

- **v1.8:** GitHub Pages browser edition with code-based online rooms, online 1v1, campaign, original soundtrack, and mobile controls.
- **v1.7:** native iOS Game Center multiplayer edition, kept under `ios/` as a separate build.

### Status and limitations

The campaign is playable without setup. The remote P2P mode uses Trystero via a CDN and public relays; it needs a live internet connection and should be tested between two real devices. Firebase mode remains optional. Room codes are intended for private casual play; they are not a replacement for robust server-side anti-cheat, abuse controls, server-authoritative scores, moderation, or professional matchmaking.
