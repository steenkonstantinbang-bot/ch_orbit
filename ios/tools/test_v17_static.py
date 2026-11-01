from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
code = (root/'OrbitZero/OrbitMultiplayer.swift').read_text()
ui = (root/'OrbitZero/ContentView.swift').read_text()
duelui = (root/'OrbitZero/DuelArenaView.swift').read_text()
pbx = (root/'OrbitZero.xcodeproj/project.pbxproj').read_text()
check = {
  'Game Center service': 'GKMatchmakerViewController(matchRequest: request)' in code,
  'Game Center invitation handler': 'GKMatchmakerViewController(invite: invite)' in code,
  'Match delegate': 'GKMatchDelegate' in code,
  'Reliable packet send': '.reliable' in code,
  'One match with exactly two players': 'request.minPlayers = 2' in code and 'request.maxPlayers = 2' in code,
  'Two points on each lap': 'addThreats(2)' in code,
  'Perfect attack sends 1 or 2': '"attack", value: 2' in code and '"attack", value: 1' in code,
  'Pressure defeat': 'threats.count >= capacity' in code,
  'No in-app power purchases in duel': 'buyWithSparks' not in code and 'SparkStore' not in code,
  'Online duel UI': 'DuelArenaView(duel: duel)' in ui,
  'Matchmaker lobby': 'arenaLobby' in ui,
  'Home multiplayer button': 'Multiplayer · Orbit Arena' in ui,
  'Version 1.7': pbx.count('MARKETING_VERSION = 1.7') == 2,
  'New source files registered': all(pbx.count(x)>=2 for x in ('OrbitMultiplayer.swift', 'DuelArenaView.swift')),
  'Game Center entitlement configured': pbx.count('CODE_SIGN_ENTITLEMENTS = OrbitZero/OrbitZero.entitlements')==2,
  'Duel board': 'private var orbitBoard' in duelui,
  'Ranking local only': 'oz.duelRating' in code,
}
for name, result in check.items(): print(('PASS' if result else 'FAIL'), name)
assert all(check.values()), 'Static validation failed'
