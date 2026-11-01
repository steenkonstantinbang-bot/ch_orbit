#!/usr/bin/env python3
"""Execute the actual OrbitMission unlock rule in Swift without iOS SDK dependencies."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "OrbitZero" / "OrbitGame.swift").read_text()
start = source.index("struct OrbitMission: Identifiable {")
end = source.index("struct ComputerPoint: Identifiable", start)
model = "import Foundation\n" + source[start:end]

checks = r'''func expect(_ actual: Int, _ expected: Int, _ context: String) {
    precondition(actual == expected, "\(context): expected \(expected), got \(actual)")
}
func cleared(_ through: Int) -> [Int: Int] {
    Dictionary(uniqueKeysWithValues: (1...through).map { ($0, 1) })
}
expect(OrbitMission.highestUnlocked(from: [:]), 1, "New install")
expect(OrbitMission.highestUnlocked(from: [1: 1]), 2, "Mission 1 unlocks 2")
expect(OrbitMission.highestUnlocked(from: [1: 3]), 2, "3 stars do not skip")
expect(OrbitMission.highestUnlocked(from: [2: 3, 40: 3]), 1, "Uncompleted first mission")
expect(OrbitMission.highestUnlocked(from: [1: 1, 2: 0, 3: 3]), 2, "Gap blocks later clears")
for previousBoss in [8, 16, 24, 32] {
    expect(OrbitMission.highestUnlocked(from: cleared(previousBoss - 1)), previousBoss, "Boss remains locked behind its previous mission")
    expect(OrbitMission.highestUnlocked(from: cleared(previousBoss)), previousBoss + 1, "Defeating boss opens next Collection")
}
expect(OrbitMission.highestUnlocked(from: cleared(39)), 40, "Final boss after 39")
expect(OrbitMission.highestUnlocked(from: cleared(40)), 40, "All missions completed")
var gap = cleared(24)
gap.removeValue(forKey: 13)
expect(OrbitMission.highestUnlocked(from: gap), 13, "Incomplete middle mission blocks progress")
print("PASS: sequential mission unlocking, all 5 Collections and legacy gaps")
'''

with tempfile.TemporaryDirectory() as temp:
    source_file = Path(temp) / "main.swift"
    source_file.write_text(model + "\n" + checks)
    binary = Path(temp) / "mission_unlock_tests"
    subprocess.run(["swiftc", str(source_file), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)

# Static guard rails to prevent accidentally restoring bypasses.
ui = (root / "OrbitZero" / "ContentView.swift").read_text()
assert "unlockAllForTesting" not in source + ui, "Debug unlock bypass present"
assert "guard isMissionUnlocked(id) else { return }" in source, "Missing game-side guard"
assert "disabled(!unlocked)" in ui, "Missing Collection lock"
assert "disabled(locked)" in ui, "Missing mission lock"
