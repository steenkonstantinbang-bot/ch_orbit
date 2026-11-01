# ORBIT ZERO v1.5 — ORIGINAL SPACE AUDIO

KONHAGEN GAMES. Music direction: restrained Scandinavian science-fiction, cinematic, futuristic. Original sound design, not a film soundtrack imitation.

## Music
- `orbit_ambient.wav` — original 48-second seamless synth loop with warm atmospheres, pulses and soft arpeggios.
- `boss_protocol.wav` — original 48-second tense loop with stronger sub-bass, percussion and faster motifs.
- Both loop automatically in AVAudioPlayer and respect Silent Mode (`.ambient` audio session).
- Boss soundtrack engages for any boss or when computer threat exceeds 65%. Music is silent in menus, on pause, and on completion.

## Sound effects
- `start.wav`: warp drive / engine ignition
- `success.wav`: brief spaceship jump blast
- `perfect.wav`: resonant PERFECT jump
- `failure.wav`: energy failure / missed gate
- `boss.wav`: dark boss warning signal
- `intercept.wav`: laser impact on computer point
- `deploy.wav`: computer deploys two points
- `surge.wav`: orbit speed boost
- `shift.wav`: gravity direction reversal
- `bomb.wav`: tactical explosion
- `victory.wav`: mission completed
- `focus.wav`: streak-based focus trigger

## Settings & integration
- Sound effects: `oz.sound` (existing)
- Music: `oz.music` (new, default on)
- Haptics: `oz.haptics` (existing)
- Scores, purchases, mission progress and game version remain unchanged.
- No network streaming; sounds bundled with app (14 PCM WAVs).
- Audio resynthesis: `python3 tools/generate_audio.py` (requires NumPy).

## QA checklist (requires macOS/Xcode)
1. Confirm audio plays on the iPhone speaker and headphones, and respects the Silent Mode switch.
2. Start any mission: soundtrack begins, each jump uses propulsion SFX.
3. Complete 360°: two computer points appear with alert SFX; intercept uses impact SFX.
4. Enter boss encounter or reach 65% computer capacity: boss music starts.
5. Lose computer pressure: ambient music returns. Pause/return home: music stops.
6. In Settings, disable just music, then just sound effects; confirm the switches are independent.
7. Verify finished/failed mission music stops and victory/failure SFX play.
