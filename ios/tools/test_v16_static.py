"""Source integration checks only; full Swift type checking requires Xcode/macOS."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
g=(root/'OrbitZero/OrbitGame.swift').read_text()
s=(root/'OrbitZero/OrbitScene.swift').read_text()
u=(root/'OrbitZero/ContentView.swift').read_text()
pbx=(root/'OrbitZero.xcodeproj/project.pbxproj').read_text()
checks={
    'v1.6 metadata in both build configs': pbx.count('MARKETING_VERSION = 1.6;') == 2 and pbx.count('CURRENT_PROJECT_VERSION = 9;') == 2,
    'preserved bundle ID': pbx.count('PRODUCT_BUNDLE_IDENTIFIER = com.konhagengames.orbitzero;') == 2,
    'all 40 missions present': len(re.findall(r'\.init\(id: \d+, title:',g)) == 40,
    'five bosses preserved': all(t in g for t in ['case 8:','case 16:', 'case 24:', 'case 32:', 'case 40:']),
    'sequential unlock gate enforced': 'return id <= unlockedMission && (id == 1 || missionStars[id - 1, default: 0] >= 1)' in g,
    'three bosses phases': 'bossHealth * 3 <= total' in g and 'PHASE III · FINAL' in g,
    'rift damage, evade and presentation': all(t in g+s+u for t in ['spawnGravityRiftIfNeeded()', 'tryDodgeRift()', 'riftArc.path', 'GRAVITY RIFT · TAP TO EVADE']),
    'dual route visible': all(t in g+s for t in ['alternateGateTurn.toggle()', 'inactiveGateArc.path']),
    'persist XP': 'd.set(pilotXP, forKey: "oz.pilotXP")' in g,
    'victory leaves time for finisher': 'finishingRemaining = mission.isBoss ? 2.3 : 1.6' in g and 'if game.isFinishing { cinematicOverlay }' in u,
    'settings and footer version': u.count('VERSION 1.6') == 2,
    'no changed apple products': (root/'APP_STORE_CONNECT_PRODUCTS.csv').exists(),
}
for name,ok in checks.items():
    print(('PASS: ' if ok else 'FAIL: ')+name)
assert all(checks.values())
