import SwiftUI

struct ContentView: View {
    @StateObject private var sender = MotionSender()
    @State private var host = "192.168.64.1"
    @State private var port = "8765"
    @State private var boost = true

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.055).ignoresSafeArea()
            VStack(spacing: 10) {
                header
                connectionRow
                liveGrid
                motionView
                gripperBar
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("OMX Teleop")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text("\(sender.source)  \(sender.status)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(sender.isRunning ? .green : .secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                sender.sendReset()
            } label: {
                Image(systemName: "scope")
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(IconButtonStyle())
            Button {
                if sender.isRunning {
                    sender.stop()
                } else {
                    sender.start(host: host, port: UInt16(port) ?? 8765, boost: boost)
                }
            } label: {
                Image(systemName: sender.isRunning ? "stop.fill" : "play.fill")
                    .frame(width: 48, height: 38)
            }
            .buttonStyle(RunButtonStyle(active: sender.isRunning))
        }
    }

    private var connectionRow: some View {
        HStack(spacing: 8) {
            TextField("Mac IP", text: $host)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            TextField("Port", text: $port)
                .keyboardType(.numberPad)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .frame(width: 72, height: 42)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            Toggle(isOn: $boost) {
                Image(systemName: "bolt.fill")
            }
            .toggleStyle(.button)
            .frame(width: 50, height: 42)
            .onChange(of: boost) { _, value in sender.boost = value }
        }
        .overlay(alignment: .bottomLeading) {
            Text(sender.connectionHint)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.secondary)
                .padding(.top, 48)
        }
    }

    private var liveGrid: some View {
        HStack(spacing: 8) {
            MetricTile(title: "X", value: sender.px)
            MetricTile(title: "Y", value: sender.py)
            MetricTile(title: "Z", value: sender.pz)
            MetricTile(title: "P", value: sender.wristPitch)
            VStack(spacing: 4) {
                Text("\(sender.packetsSent)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("pkt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 46, height: 64)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var motionView: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let pad = min(width, 280)
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.055))
                    Circle()
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                        .frame(width: pad * 0.68, height: pad * 0.68)
                    Rectangle()
                        .fill(.white.opacity(0.10))
                        .frame(width: 1, height: pad * 0.78)
                    Rectangle()
                        .fill(.white.opacity(0.10))
                        .frame(width: pad * 0.78, height: 1)
                    Path { path in
                        path.move(to: CGPoint(x: pad * 0.5, y: pad * 0.5))
                        path.addLine(to: CGPoint(
                            x: pad * (0.5 + sender.py * 0.35),
                            y: pad * (0.5 - sender.px * 0.35)
                        ))
                    }
                    .stroke(.cyan.opacity(0.42), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Circle()
                        .stroke(.cyan.opacity(sender.linkPulse ? 0.28 : 0.08), lineWidth: 2)
                        .frame(
                            width: 42 + CGFloat(sender.motionIntensity) * 26,
                            height: 42 + CGFloat(sender.motionIntensity) * 26
                        )
                        .offset(x: sender.py * pad * 0.35, y: -sender.px * pad * 0.35)
                        .animation(.easeOut(duration: 0.12), value: sender.linkPulse)
                    Circle()
                        .fill(.cyan)
                        .frame(
                            width: 20 + CGFloat(sender.motionIntensity) * 5,
                            height: 20 + CGFloat(sender.motionIntensity) * 5
                        )
                        .shadow(color: .cyan.opacity(0.8), radius: 12)
                        .offset(x: sender.py * pad * 0.35, y: -sender.px * pad * 0.35)
                    VStack {
                        HStack {
                            syncBadge
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(10)
                }
                .frame(width: pad, height: pad)

                VStack(spacing: 8) {
                    Text("Z")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    GeometryReader { bar in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.cyan)
                                .frame(height: max(8, bar.size.height * CGFloat((sender.pz + 1) * 0.5)))
                        }
                    }
                    Text(cmText(sender.pz))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .frame(width: 48, height: pad)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 292)
    }

    private var gripperBar: some View {
        HStack(spacing: 10) {
            Image(systemName: sender.gripperOpen > 0.5 ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Gripper")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Text("\(Int(sender.gripperOpen * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                ProgressView(value: sender.gripperOpen)
                    .tint(.cyan)
            }
        }
        .padding(10)
        .frame(height: 58)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }

    private func cmText(_ value: Double) -> String {
        let cm = Int((abs(value) * 100).rounded())
        if cm == 0 { return "0" }
        return value > 0 ? "+\(cm)" : "-\(cm)"
    }
}

private struct MetricTile: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(cmText(value))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            ProgressView(value: (value + 1.0) * 0.5)
                .tint(.cyan)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }

    private func cmText(_ value: Double) -> String {
        let cm = Int((abs(value) * 100).rounded())
        if cm == 0 { return "0" }
        return value > 0 ? "+\(cm)" : "-\(cm)"
    }
}

private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct RunButtonStyle: ButtonStyle {
    let active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(active ? .red.opacity(0.85) : .cyan, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(active ? .white : .black)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private var syncBadge: some View {
    HStack(spacing: 6) {
        Circle()
            .fill(.green)
            .frame(width: 8, height: 8)
        Text("LIVE")
            .font(.system(size: 11, weight: .black, design: .rounded))
    }
    .padding(.horizontal, 8)
    .frame(height: 24)
    .background(.black.opacity(0.35), in: Capsule())
}
