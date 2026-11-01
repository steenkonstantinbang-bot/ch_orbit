import SpriteKit
import UIKit


extension UIColor {
    static let accent = UIColor(red: 0.60, green: 0.72, blue: 0.76, alpha: 1)
    static let accentStrong = UIColor(red: 0.79, green: 0.88, blue: 0.90, alpha: 1)
    static let rose = UIColor(red: 0.72, green: 0.57, blue: 0.59, alpha: 1)
    static let sand = UIColor(red: 0.83, green: 0.77, blue: 0.66, alpha: 1)
    static let background = UIColor(red: 0.06, green: 0.08, blue: 0.09, alpha: 1)
    static let panelLine = UIColor(red: 0.20, green: 0.24, blue: 0.27, alpha: 1)
    static let mist = UIColor(red: 0.62, green: 0.68, blue: 0.72, alpha: 1)
    // Compatibility aliases used by OrbitGame
    static let aqua = accent
    static let pink = rose
    static let gold = sand
    static let navy = background
}

final class OrbitScene: SKScene {
    weak var game: OrbitGame?
    private let world = SKNode()
    private let orbit = SKShapeNode()
    private let orbitInner = SKShapeNode()
    private let orbitOuter = SKShapeNode()
    private let gateGlow = SKShapeNode()
    private let gateArc = SKShapeNode()
    private let inactiveGateArc = SKShapeNode()
    private let riftArc = SKShapeNode()
    private let gateCenter = SKShapeNode(circleOfRadius: 4)
    private let decoyGlow = SKShapeNode()
    private let decoyArc = SKShapeNode()
    private let coreAura = SKShapeNode(circleOfRadius: 76)
    private let coreShell = SKShapeNode()
    private let coreInner = SKShapeNode(circleOfRadius: 12)
    private let coreName = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let bossLives = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let ship = SKShapeNode()
    private let shipGlow = SKShapeNode(circleOfRadius: 15)
    private let prompt = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let countdown = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let trail = (0..<9).map { _ in SKShapeNode(circleOfRadius: 2.7) }
    private var stars: [SKShapeNode] = []
    private var pointNodes: [UUID: SKShapeNode] = [:]
    private var lastVisualShipID = ""
    private var installed = false
    private var clock: TimeInterval = 0
    private var previousFrame: TimeInterval = 0

    private var centerPoint: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.51) }
    private var orbitRadius: CGFloat { min(size.width * 0.345, size.height * 0.235, 175) }

    override func didMove(to view: SKView) {
        guard !installed else { return }
        installed = true
        backgroundColor = .background
        view.isMultipleTouchEnabled = false
        addChild(world)
        installStars()
        for (node, z) in [(orbitOuter, 0), (orbitInner, 1), (orbit, 2),
                          (gateGlow, 4), (gateArc, 5), (inactiveGateArc, 3), (riftArc, 6), (gateCenter, 6),
                          (decoyGlow, 3), (decoyArc, 5),
                          (coreAura, 7), (coreShell, 8), (coreInner, 9),
                          (shipGlow, 13), (ship, 14)] {
            node.zPosition = CGFloat(z)
            world.addChild(node)
        }
        for (index, node) in trail.enumerated() {
            node.fillColor = .mist
            node.strokeColor = .clear
            node.alpha = CGFloat(index + 1) / 20
            node.zPosition = 11
            world.addChild(node)
        }
        orbit.strokeColor = UIColor.panelLine
        orbit.lineWidth = 1.5
        orbitInner.strokeColor = UIColor.panelLine.withAlphaComponent(0.5)
        orbitInner.lineWidth = 1
        orbitOuter.strokeColor = UIColor.panelLine.withAlphaComponent(0.5)
        orbitOuter.lineWidth = 1
        gateGlow.strokeColor = .accent
        gateGlow.alpha = 0.12
        gateGlow.lineWidth = 16
        gateGlow.glowWidth = 10
        gateArc.strokeColor = .accent
        gateArc.lineWidth = 8
        gateArc.glowWidth = 4
        inactiveGateArc.strokeColor = .mist
        inactiveGateArc.alpha = 0.30
        inactiveGateArc.lineWidth = 5
        inactiveGateArc.isHidden = true
        riftArc.strokeColor = .sand
        riftArc.alpha = 0.92
        riftArc.lineWidth = 9
        riftArc.glowWidth = 3
        riftArc.isHidden = true
        gateCenter.fillColor = .white
        gateCenter.strokeColor = .clear
        gateCenter.glowWidth = 4
        decoyGlow.strokeColor = .rose
        decoyGlow.alpha = 0.09
        decoyGlow.lineWidth = 14
        decoyGlow.glowWidth = 8
        decoyArc.strokeColor = .rose
        decoyArc.alpha = 0.55
        decoyArc.lineWidth = 7
        decoyArc.glowWidth = 3
        decoyGlow.isHidden = true
        decoyArc.isHidden = true
        coreAura.fillColor = UIColor.accent.withAlphaComponent(0.10)
        coreAura.strokeColor = .clear
        coreAura.glowWidth = 4
        coreShell.lineWidth = 2
        coreShell.glowWidth = 4
        coreInner.fillColor = .accent
        coreInner.strokeColor = .clear
        coreInner.glowWidth = 4
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: 0, y: 14))
        shipPath.addLine(to: CGPoint(x: -9, y: -10))
        shipPath.addLine(to: CGPoint(x: 0, y: -5))
        shipPath.addLine(to: CGPoint(x: 9, y: -10))
        shipPath.closeSubpath()
        ship.path = shipPath
        ship.fillColor = .white
        ship.strokeColor = .accent
        ship.lineWidth = 1.5
        ship.glowWidth = 5
        shipGlow.fillColor = UIColor.accent.withAlphaComponent(0.05)
        shipGlow.strokeColor = .clear
        for label in [coreName, bossLives, prompt, countdown] {
            label.zPosition = 15
            label.horizontalAlignmentMode = .center
            world.addChild(label)
        }
        coreName.fontSize = 11
        coreName.fontColor = .mist
        bossLives.fontSize = 13
        prompt.fontSize = 10
        prompt.fontColor = .accent
        countdown.fontSize = 11
        countdown.fontColor = .mist
        layoutScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if installed { layoutScene() }
    }

    private func installStars() {
        for index in 0..<56 {
            let r: CGFloat = index.isMultiple(of: 7) ? 1.35 : 0.65
            let node = SKShapeNode(circleOfRadius: r)
            node.fillColor = UIColor(red: 0.63, green: 0.80, blue: 0.87, alpha: 1)
            node.strokeColor = .clear
            node.alpha = CGFloat((index * 37) % 7 + 1) / 24
            node.zPosition = -5
            world.addChild(node)
            stars.append(node)
            let fade = SKAction.sequence([.fadeAlpha(to: 0.07, duration: 1.8 + Double(index % 5) * 0.6),
                                          .fadeAlpha(to: 0.24, duration: 1.8 + Double(index % 5) * 0.6)])
            node.run(.repeatForever(fade))
        }
    }

    private func layoutScene() {
        guard installed else { return }
        let c = centerPoint, r = orbitRadius
        for (index, star) in stars.enumerated() {
            let x = CGFloat((index * 127 + 41) % 991) / 991 * size.width
            let y = CGFloat((index * 293 + 93) % 997) / 997 * size.height
            star.position = CGPoint(x: x, y: y)
        }
        for (node, radius) in [(orbit, r), (orbitInner, r - 13), (orbitOuter, r + 14)] {
            node.path = CGPath(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius,
                                                 width: 2 * radius, height: 2 * radius), transform: nil)
        }
        coreAura.position = c
        coreShell.position = c
        coreInner.position = c
        coreName.position = CGPoint(x: c.x, y: c.y - 81)
        bossLives.position = CGPoint(x: c.x, y: c.y - 101)
        prompt.position = CGPoint(x: c.x, y: c.y + r + 59)
        countdown.position = CGPoint(x: c.x, y: c.y - r - 52)
        redraw()
    }

    private func arc(radius: CGFloat, from: CGFloat, to: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.addArc(center: centerPoint, radius: radius, startAngle: from, endAngle: to, clockwise: false)
        return p
    }

    private func polygon(sides: Int, radius: CGFloat) -> CGPath {
        let p = CGMutablePath()
        for index in 0..<sides {
            let a = CGFloat(index) / CGFloat(sides) * .pi * 2 - .pi / 2
            let point = CGPoint(x: cos(a) * radius, y: sin(a) * radius)
            if index == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
    }

    private func redraw() {
        guard let game = game, installed else { return }
        let r = orbitRadius
        let w = CGFloat(game.gateWidth)
        let a = CGFloat(game.gate)
        let theta = CGFloat(game.angle)
        let activeGateColor: UIColor = game.isChargeGate ? .sand : .accent
        gateGlow.strokeColor = activeGateColor
        gateArc.strokeColor = activeGateColor
        gateGlow.path = arc(radius: r, from: a - w, to: a + w)
        gateArc.path = arc(radius: r, from: a - w + 0.025, to: a + w - 0.025)
        gateCenter.position = CGPoint(x: centerPoint.x + cos(a) * r, y: centerPoint.y + sin(a) * r)
        inactiveGateArc.isHidden = !game.dualGateActive
        if game.dualGateActive {
            let inactive = CGFloat(game.inactiveGateAngle)
            inactiveGateArc.path = arc(radius: r, from: inactive - w * 0.9, to: inactive + w * 0.9)
        }
        riftArc.isHidden = game.riftAngle == nil
        if let rift = game.riftAngle {
            let riftA = CGFloat(rift)
            riftArc.path = arc(radius: r, from: riftA - 0.17, to: riftA + 0.17)
            riftArc.alpha = 0.65 + 0.24 * CGFloat(abs(sin(clock * 5)))
        }
        if let fake = game.decoyGate {
            let f = CGFloat(fake)
            decoyGlow.isHidden = false
            decoyArc.isHidden = false
            decoyGlow.path = arc(radius: r, from: f - w, to: f + w)
            decoyArc.path = arc(radius: r, from: f - w + 0.025, to: f + w - 0.025)
            decoyArc.alpha = 0.50 + 0.30 * CGFloat(abs(sin(clock * 3)))
        } else {
            decoyGlow.isHidden = true
            decoyArc.isHidden = true
        }
        syncComputerPoints(game)
        let x = centerPoint.x + cos(theta) * r
        let y = centerPoint.y + sin(theta) * r
        ship.position = CGPoint(x: x, y: y)
        ship.zRotation = theta
        shipGlow.position = ship.position
        // Skins only affect visual colors. Physics, sizes and hit detection are unchanged.
        if lastVisualShipID != game.equippedShipID {
            lastVisualShipID = game.equippedShipID
            applyShipSilhouette(game.equippedShipID)
        }
        let palette = cosmeticPalette(game.equippedShipID)
        ship.fillColor = palette.fill
        ship.strokeColor = palette.outline
        shipGlow.fillColor = palette.outline.withAlphaComponent(0.07)
        for node in trail { node.fillColor = palette.trail }
        for (index, node) in trail.enumerated() {
            let prev = theta - CGFloat(index + 1) * 0.052
            node.position = CGPoint(x: centerPoint.x + cos(prev) * r, y: centerPoint.y + sin(prev) * r)
        }
        let boss = game.isBossWave
        let phaseTwo = game.eclipseArmor
        let sides = game.bossType == .eclipse ? 9 : game.bossType == .prism ? 8 : game.bossType == .vortex ? 5 : 7
        coreShell.path = polygon(sides: boss ? sides : 6, radius: boss ? (phaseTwo ? 49 : 43) : 39)
        coreShell.fillColor = boss ? UIColor(red: 0.18, green: 0.12, blue: 0.13, alpha: 1) : UIColor(red: 0.10, green: 0.12, blue: 0.13, alpha: 1)
        coreShell.strokeColor = phaseTwo || game.focusActive ? .sand : boss ? .rose : .accent
        coreShell.zRotation = CGFloat(clock) * (boss ? (game.bossPhase == 3 ? -0.82 : -0.47) : 0.24)
        coreInner.fillColor = phaseTwo ? .sand : boss ? .rose : .accent
        let danger = game.computerFraction
        coreAura.fillColor = (danger >= 0.70 ? UIColor.rose : (boss ? UIColor.rose : UIColor.accent))
            .withAlphaComponent(0.10 + danger * 0.15 + sin(clock * 2.7) * 0.03)
        coreName.text = boss ? game.bossTitle : "ORBIT CORE"
        coreName.fontSize = boss && game.bossTitle.count > 13 ? 9 : 11
        bossLives.text = boss ? "PHASE \(game.bossPhase) / 3  ·  HP \(game.bossHealth)" : ""
        bossLives.fontSize = game.bossHealth > 6 ? 10 : 13
        bossLives.fontColor = .rose
        if game.riftApproaching {
            prompt.text = "GRAVITY RIFT · TAP TO EVADE"
        } else if game.riftAngle != nil {
            prompt.text = "AMBER ARC = DANGER · TAP TO EVADE"
        } else if game.dualGateActive {
            prompt.text = "DUAL ROUTE · BRIGHT GATE ONLY"
        } else if boss {
            prompt.text = game.eclipseArmor ? "ARMOR · PERFECT ONLY" :
                (game.bossType == .mirage || game.bossType == .prism) ? "ROSE GATE IS FALSE" :
                game.surgeActive ? "SURGE · KEEP YOUR RHYTHM" : "BOSS ENCOUNTER"
        } else if game.computerOverdrive {
            prompt.text = "AI OVERDRIVE · CLEAR RED POINTS"
        } else if game.isChargeGate {
            prompt.text = "GOLD GATE · PERFECT TO CHARGE"
        } else if game.surgeActive {
            prompt.text = "SURGE · SPEED BOOST"
        } else if game.decoyGate != nil {
            prompt.text = "ROSE GATE IS FALSE"
        } else if game.focusActive {
            prompt.text = "FOCUS · SLOW MOTION"
        } else if game.pulseActive {
            prompt.text = "PULSE · WAIT FOR WIDE GATE"
        } else if game.reversalActive {
            prompt.text = "DIRECTION MAY CHANGE"
        } else {
            prompt.text = game.isDaily ? "DAILY CHALLENGE" : "TIME YOUR JUMP"
        }
        prompt.fontSize = (prompt.text?.count ?? 0) > 23 ? 9 : 10
        prompt.fontColor = boss ? .rose : .accent
        countdown.text = game.isPlaying ? "TIME \(game.timeSeconds) · LAP \(game.orbitCount)" : "Minimal orbit arcade"
    }

    // Persistent red threat points. Their positions are fixed until the user taps
    // as the orbiting ship aligns with them. Changes are reflected every frame.
    private func syncComputerPoints(_ game: OrbitGame) {
        let active = Set(game.computerPoints.map(\.id))
        for id in pointNodes.keys.filter({ !active.contains($0) }) {
            pointNodes.removeValue(forKey: id)?.removeFromParent()
        }
        let radius = orbitRadius
        for point in game.computerPoints {
            let node: SKShapeNode
            if let existing = pointNodes[point.id] {
                node = existing
            } else {
                let outer = SKShapeNode(circleOfRadius: 9)
                outer.strokeColor = .rose
                outer.fillColor = UIColor.background
                outer.lineWidth = 2.5
                outer.glowWidth = 5
                outer.zPosition = 12
                let inner = SKShapeNode(circleOfRadius: 3)
                inner.fillColor = .rose
                inner.strokeColor = .clear
                outer.addChild(inner)
                outer.setScale(0.2)
                outer.run(.scale(to: 1.0, duration: 0.22))
                world.addChild(outer)
                pointNodes[point.id] = outer
                node = outer
            }
            let a = CGFloat(point.angle)
            node.position = CGPoint(x: centerPoint.x + cos(a) * radius,
                                    y: centerPoint.y + sin(a) * radius)
            node.alpha = 0.80 + 0.20 * CGFloat(abs(sin(clock * 3.4)))
        }
    }

    func emitComputerDeployment() {
        guard game?.effectsEnabled == true else { return }
        emitShockwave(color: .rose)
        floatingTitle("+2 COMPUTER POINTS", color: .rose, size: 16)
    }

    func emitComputerIntercept(at angle: Double) {
        guard game?.effectsEnabled == true else { return }
        let r = orbitRadius
        let point = CGPoint(x: centerPoint.x + cos(CGFloat(angle)) * r,
                            y: centerPoint.y + sin(CGFloat(angle)) * r)
        for index in 0..<14 {
            let shard = SKShapeNode(circleOfRadius: 1.6)
            shard.fillColor = .rose
            shard.strokeColor = .clear
            shard.position = point
            shard.zPosition = 27
            world.addChild(shard)
            let a = CGFloat(index) * .pi * 2 / 14
            let d: CGFloat = CGFloat.random(in: 16...48)
            shard.run(.sequence([
                .group([.moveBy(x: cos(a) * d, y: sin(a) * d, duration: 0.3),
                        .fadeOut(withDuration: 0.3)]), .removeFromParent()
            ]))
        }
    }

    func emitComputerVictory() {
        emitShockwave(color: .rose)
        shake(intensity: 16)
        floatingTitle("COMPUTER WINS", color: .rose, size: 24)
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = previousFrame == 0 ? 0.016 : min(0.05, max(0, currentTime - previousFrame))
        previousFrame = currentTime
        clock += dt
        game?.advance(dt)
        redraw()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if game?.isPlaying == true { game?.jump() }
    }

    /// Each skin has its own Nordic geometric silhouette (display-only).
    /// Size remains within the original ship footprint, so game timing is unaffected.
    private func applyShipSilhouette(_ id: String) {
        let points: [CGPoint]
        switch id {
        case "aurora", "frostglass":
            points = [CGPoint(x: 0, y: 17), CGPoint(x: -6, y: 3), CGPoint(x: -4, y: -10),
                      CGPoint(x: 0, y: -5), CGPoint(x: 4, y: -10), CGPoint(x: 6, y: 3)]
        case "monolith", "copper":
            points = [CGPoint(x: 0, y: 14), CGPoint(x: -10, y: 6), CGPoint(x: -10, y: -6),
                      CGPoint(x: -4, y: -12), CGPoint(x: 4, y: -12), CGPoint(x: 10, y: -6), CGPoint(x: 10, y: 6)]
        case "equinox", "nordicgold":
            points = [CGPoint(x: 0, y: 16), CGPoint(x: -8, y: 5), CGPoint(x: -7, y: -9),
                      CGPoint(x: 0, y: -3), CGPoint(x: 7, y: -9), CGPoint(x: 8, y: 5)]
        case "obsidian", "void":
            points = [CGPoint(x: 0, y: 14), CGPoint(x: -11, y: 3), CGPoint(x: -6, y: -9),
                      CGPoint(x: 0, y: -5), CGPoint(x: 6, y: -9), CGPoint(x: 11, y: 3)]
        case "zenith":
            points = [CGPoint(x: 0, y: 18), CGPoint(x: -5, y: 4), CGPoint(x: -11, y: 1),
                      CGPoint(x: -7, y: -10), CGPoint(x: 0, y: -5), CGPoint(x: 7, y: -10),
                      CGPoint(x: 11, y: 1), CGPoint(x: 5, y: 4)]
        default:
            points = [CGPoint(x: 0, y: 14), CGPoint(x: -9, y: -10), CGPoint(x: 0, y: -5), CGPoint(x: 9, y: -10)]
        }
        let path = CGMutablePath()
        guard let first = points.first else { return }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        ship.path = path
    }

    // Colors for free mastery skins and permanent premium designs.
    private func cosmeticPalette(_ id: String) -> (fill: UIColor, outline: UIColor, trail: UIColor) {
        switch id {
        case "aurora": return (.accentStrong, .accent, .accentStrong)
        case "monolith": return (UIColor(red: 0.50, green: 0.55, blue: 0.58, alpha: 1), .accentStrong, .mist)
        case "equinox": return (UIColor(red: 0.79, green: 0.80, blue: 0.85, alpha: 1), .white, .accent)
        case "obsidian": return (UIColor(red: 0.16, green: 0.19, blue: 0.21, alpha: 1), .accentStrong, .mist)
        case "zenith": return (.white, .sand, .sand)
        case "nordicgold": return (.sand, .sand, .sand)
        case "frostglass": return (UIColor(red: 0.72, green: 0.91, blue: 0.95, alpha: 1), .white, .accentStrong)
        case "copper": return (UIColor(red: 0.79, green: 0.51, blue: 0.37, alpha: 1), .sand, UIColor(red: 0.79, green: 0.51, blue: 0.37, alpha: 1))
        case "void": return (UIColor(red: 0.08, green: 0.11, blue: 0.14, alpha: 1), .white, .accent)
        default: return (.white, .accent, .mist)
        }
    }

    /// Distinct, lightweight animations for equipable visual signatures.
    /// Called on PERFECT hits and mission victories, never changes score or timing.
    func emitSignatureEffect(atShip: Bool) {
        guard let game, game.effectsEnabled else { return }
        let id = game.equippedEffectID
        guard id != "classic" else { return }
        let origin = atShip ? ship.position : centerPoint
        switch id {
        case "aurorawave", "zenithcrown":
            let color: UIColor = id == "zenithcrown" ? .sand : .accentStrong
            for step in 0..<(id == "zenithcrown" ? 3 : 2) {
                let ring = SKShapeNode(circleOfRadius: 12)
                ring.fillColor = .clear
                ring.strokeColor = color
                ring.lineWidth = id == "zenithcrown" ? 2.4 : 1.7
                ring.glowWidth = 2
                ring.alpha = 0
                ring.position = origin
                ring.zPosition = 34
                world.addChild(ring)
                ring.run(.sequence([
                    .wait(forDuration: Double(step) * 0.11),
                    .group([.fadeAlpha(to: 0.85, duration: 0.10), .scale(to: 1.5, duration: 0.10)]),
                    .group([.scale(to: id == "zenithcrown" ? 7 : 5, duration: 0.65), .fadeOut(withDuration: 0.65)]),
                    .removeFromParent()
                ]))
            }
        case "prismburst":
            for index in 0..<9 {
                let a = CGFloat(index) / 9 * .pi * 2
                let diamond = SKShapeNode(rectOf: CGSize(width: 5, height: 5), cornerRadius: 0.8)
                diamond.fillColor = index.isMultiple(of: 2) ? .accentStrong : .sand
                diamond.strokeColor = .clear
                diamond.zRotation = .pi / 4
                diamond.position = origin
                diamond.zPosition = 35
                world.addChild(diamond)
                let v = CGVector(dx: cos(a) * 87, dy: sin(a) * 87)
                diamond.run(.sequence([.group([.move(by: v, duration: 0.52), .rotate(byAngle: .pi, duration: 0.52),
                                               .scale(to: 0.12, duration: 0.52), .fadeOut(withDuration: 0.52)]), .removeFromParent()]))
            }
        case "stardust":
            for index in 0..<16 {
                let a = CGFloat(index) / 16 * .pi * 2
                let star = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 2.3 : 1.3)
                star.fillColor = index.isMultiple(of: 2) ? .sand : .accentStrong
                star.strokeColor = .clear
                star.position = origin
                star.zPosition = 34
                world.addChild(star)
                let d = CGFloat(52 + index % 4 * 19)
                star.run(.sequence([.group([.move(by: CGVector(dx: cos(a) * d, dy: sin(a) * d), duration: 0.72),
                                            .fadeOut(withDuration: 0.72)]), .removeFromParent()]))
            }
        default: break
        }
    }

    func emitBurst(atShip: Bool, color: UIColor, count: Int) {
        guard game?.effectsEnabled == true else { return }
        let origin = atShip ? ship.position : centerPoint
        // Minimalist, battery-friendlier bursts instead of full-screen particle showers.
        for _ in 0..<min(count, 45) {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.9...2.2))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.glowWidth = 1
            particle.position = origin
            particle.zPosition = 30
            world.addChild(particle)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 35...120)
            let duration = Double.random(in: 0.28...0.82)
            let displacement = CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance)
            particle.run(.sequence([.group([.move(by: displacement, duration: duration),
                                            .fadeOut(withDuration: duration),
                                            .scale(to: 0.2, duration: duration)]), .removeFromParent()]))
        }
    }

    func emitShockwave(color: UIColor) {
        guard game?.effectsEnabled == true else { return }
        let ring = SKShapeNode(circleOfRadius: 4)
        ring.position = centerPoint
        ring.strokeColor = color
        ring.lineWidth = 2
        ring.glowWidth = 3
        ring.zPosition = 17
        world.addChild(ring)
        let radius = orbitRadius * 1.5
        ring.run(.sequence([.group([.scale(to: radius / 4, duration: 0.65),
                                    .fadeOut(withDuration: 0.65)]), .removeFromParent()]))
    }

    func shake(intensity: CGFloat) {
        guard game?.effectsEnabled == true else { return }
        world.removeAction(forKey: "shake")
        let actions = (0..<6).map { _ in SKAction.moveBy(x: CGFloat.random(in: -intensity...intensity),
                                                       y: CGFloat.random(in: -intensity...intensity), duration: 0.035) }
        world.run(.sequence(actions + [.move(to: .zero, duration: 0.06)]), withKey: "shake")
    }

    // Dynamic, short-lived effects; all effects obey the player's Particles setting.
    private func floatingTitle(_ title: String, color: UIColor, size: CGFloat = 20) {
        guard game?.effectsEnabled == true else { return }
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = size
        label.fontColor = color
        label.position = CGPoint(x: centerPoint.x, y: centerPoint.y + orbitRadius + 28)
        label.zPosition = 32
        label.alpha = 0
        world.addChild(label)
        label.run(.sequence([.group([.fadeIn(withDuration: 0.12), .moveBy(x: 0, y: 10, duration: 0.25)]),
                             .wait(forDuration: 0.35),
                             .group([.fadeOut(withDuration: 0.28), .moveBy(x: 0, y: 18, duration: 0.28)]),
                             .removeFromParent()]))
    }

    func emitChargeCapture() {
        emitShockwave(color: .sand)
        emitBurst(atShip: true, color: .sand, count: 34)
        floatingTitle("CHARGE +1", color: .sand, size: 18)
    }

    func emitComboMilestone(combo: Int) {
        emitShockwave(color: .accentStrong)
        floatingTitle("\(combo)× COMBO", color: .accentStrong, size: 19)
        let ring = SKShapeNode(circleOfRadius: orbitRadius * 0.84)
        ring.strokeColor = .accentStrong
        ring.lineWidth = 1.5
        ring.fillColor = .clear
        ring.zPosition = 16
        ring.position = centerPoint
        ring.alpha = 0.8
        world.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 1.35, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
    }

    func emitSurge() {
        emitShockwave(color: .rose)
        floatingTitle("SURGE", color: .rose, size: 20)
    }

    func emitBossIntro(title: String) {
        emitShockwave(color: .rose)
        floatingTitle(title, color: .rose, size: 15)
        emitBurst(atShip: false, color: .rose, count: 36)
    }

    func emitRiftWarning(at angle: Double) {
        guard game?.effectsEnabled == true else { return }
        emitShockwave(color: .sand)
        floatingTitle("GRAVITY RIFT", color: .sand, size: 16)
    }

    func emitRiftDodge(at angle: Double) {
        guard game?.effectsEnabled == true else { return }
        emitShockwave(color: .accentStrong)
        floatingTitle("EVADED", color: .accentStrong, size: 16)
        emitBurst(atShip: true, color: .sand, count: 28)
    }

    func emitBossPhase(title: String) {
        emitShockwave(color: .rose)
        emitShockwave(color: .sand)
        emitBurst(atShip: false, color: .rose, count: 65)
        floatingTitle(title, color: .sand, size: 19)
        shake(intensity: 9)
    }

    func emitVictory(title: String, boss: Bool) {
        emitShockwave(color: .sand)
        emitBurst(atShip: false, color: .sand, count: boss ? 100 : 50)
        floatingTitle(title, color: .sand, size: boss ? 19 : 18)
        // Multi-ring controlled finisher; the model delays the results menu so it can play.
        if game?.effectsEnabled == true {
            for i in 0..<(boss ? 5 : 3) {
                let ring = SKShapeNode(circleOfRadius: 22)
                ring.position = centerPoint
                ring.lineWidth = i.isMultiple(of: 2) ? 2.4 : 1.1
                ring.strokeColor = i.isMultiple(of: 2) ? .sand : .accentStrong
                ring.fillColor = .clear
                ring.alpha = 0
                ring.zPosition = 32
                world.addChild(ring)
                ring.run(.sequence([
                    .wait(forDuration: Double(i) * 0.19),
                    .fadeAlpha(to: 0.85, duration: 0.08),
                    .group([.scale(to: boss ? 9.5 : 7.5, duration: 0.95), .fadeOut(withDuration: 0.95)]),
                    .removeFromParent()
                ]))
            }
        }
        if boss {
            let shards = 12
            for i in 0..<shards {
                let angle = CGFloat(i) / CGFloat(shards) * .pi * 2
                let shard = SKShapeNode(rectOf: CGSize(width: 2, height: 18), cornerRadius: 1)
                shard.position = centerPoint
                shard.zRotation = -angle
                shard.fillColor = .sand
                shard.strokeColor = .clear
                shard.zPosition = 35
                world.addChild(shard)
                let dist: CGFloat = orbitRadius * 1.2
                let vec = CGVector(dx: cos(angle)*dist, dy: sin(angle)*dist)
                shard.run(.sequence([.group([.move(by: vec, duration: 0.65), .fadeOut(withDuration: 0.65), .scale(to: 0.3, duration: 0.65)]), .removeFromParent()]))
            }
        }
    }

    func clearEffects() {
        world.children.filter { $0.zPosition >= 17 }.forEach { $0.removeFromParent() }
        world.removeAction(forKey: "shake")
        world.position = .zero
    }
}
