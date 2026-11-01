import SwiftUI

// Intentionally separate from the single-player SpriteKit scene: battles cannot
// unlock story missions or spend tactical power-ups.
struct DuelArenaView: View {
    @ObservedObject var duel: OrbitDuelGame
    private let back = Color(red: 0.06, green: 0.08, blue: 0.09)
    private let soft = Color(red: 0.72, green: 0.83, blue: 0.85)
    private let danger = Color(red: 0.79, green: 0.51, blue: 0.53)
    private let panel = Color(red: 0.12, green: 0.14, blue: 0.15)

    var body: some View {
        GeometryReader { geo in
            let short = geo.size.height < 700
            VStack(spacing: short ? 10 : 17) {
                HStack {
                    Button(action: duel.exit) {
                        Label("Exit", systemImage: "chevron.left")
                    }
                    .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("ORBIT ARENA · ONLINE")
                        .font(.system(size: 10, weight: .semibold)).tracking(1.3)
                        .foregroundStyle(soft)
                }
                HStack(spacing: 8) {
                    playerCard("YOU", score: duel.score, pressure: duel.pressure, active: true)
                    Text("VS").font(.system(size: 11, weight: .semibold)).foregroundStyle(.gray)
                    playerCard(duel.opponent, score: duel.rivalScore, pressure: duel.rivalPressure, active: false)
                }
                HStack {
                    Text("TIME  \(duel.seconds)s")
                    Spacer()
                    Text("LAPS  \(duel.laps)")
                    Spacer()
                    Text("SHIELDS  \(String(repeating: "◆", count: duel.shields))")
                }
                .font(.system(size: 11, weight: .semibold)).monospacedDigit()
                .foregroundStyle(.white.opacity(0.82))

                orbitBoard
                    .frame(maxWidth: .infinity)
                    .frame(height: min(geo.size.width - 34, short ? 295 : 370))
                    .contentShape(Rectangle())
                    .onTapGesture { duel.jump() }

                Text(duel.message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(duel.phase == .playing ? soft : danger)
                    .lineLimit(2)
                    .frame(height: 27)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                if duel.phase == .playing {
                    Button(action: duel.jump) {
                        Text("JUMP  /  INTERCEPT")
                            .font(.system(size: 16, weight: .semibold)).tracking(0.7)
                            .frame(maxWidth: .infinity).frame(height: short ? 51 : 58)
                            .foregroundStyle(back)
                            .background(soft, in: RoundedRectangle(cornerRadius: 14))
                    }
                    Text("Tap at a pale gate or red point. Every lap adds 2 points.\n3 PERFECT hits send an extra attack.")
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 12) {
                        Text(duel.resultTitle)
                            .font(.system(size: 32, weight: .semibold))
                        Text("DUEL RATING  \(duel.rating)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(soft)
                        Button("Back to main menu", action: duel.exit)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity).frame(height: 49)
                            .background(panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 11)
            .padding(.bottom, short ? 7 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(back.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func playerCard(_ title: String, score: Int, pressure: Int, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(soft).lineLimit(1)
            Text(score.formatted())
                .font(.system(size: 23, weight: .semibold)).monospacedDigit()
            HStack(spacing: 2) {
                ForEach(0..<12, id: \.self) { i in
                    Capsule().fill(i < pressure ? danger : Color.white.opacity(0.10)).frame(height: 5)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panel, in: RoundedRectangle(cornerRadius: 13))
    }

    private var orbitBoard: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) * 0.355
            let circle = Path(ellipseIn: CGRect(x: centre.x-r, y: centre.y-r, width: r*2, height: r*2))
            context.stroke(circle, with: .color(soft.opacity(0.27)), lineWidth: 1.7)
            for threat in duel.threats {
                let a = threat.angle
                let p = CGPoint(x: centre.x + CGFloat(cos(a))*r, y: centre.y - CGFloat(sin(a))*r)
                let point = Path(ellipseIn: CGRect(x:p.x-7, y:p.y-7, width:14,height:14))
                context.fill(point, with: .color(danger))
                context.stroke(point, with: .color(.white.opacity(0.7)), lineWidth: 1)
            }
            let g = duel.gate
            let arcCenter = CGPoint(x:centre.x + CGFloat(cos(g))*r, y:centre.y - CGFloat(sin(g))*r)
            let target = Path(ellipseIn: CGRect(x:arcCenter.x-13, y:arcCenter.y-13, width:26,height:26))
            context.stroke(target, with: .color(soft), lineWidth: 6)
            let a = duel.angle
            let shipP = CGPoint(x:centre.x + CGFloat(cos(a))*r, y:centre.y - CGFloat(sin(a))*r)
            let ship = Path(ellipseIn: CGRect(x:shipP.x-6, y:shipP.y-6, width:12,height:12))
            context.fill(ship, with: .color(.white))
            let centerCore = Path(ellipseIn: CGRect(x:centre.x-29, y:centre.y-29, width:58,height:58))
            context.fill(centerCore, with: .color(panel))
            context.stroke(centerCore, with: .color(soft.opacity(0.7)), lineWidth: 2)
            context.draw(Text("OZ").font(.system(size: 15, weight: .bold)).foregroundColor(soft), at: centre)
        }
    }
}
