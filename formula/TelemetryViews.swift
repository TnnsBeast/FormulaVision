import SwiftUI
import Foundation

struct TelemetryRootView: View {
    @ObservedObject var model: TelemetryViewModel

    var body: some View {
        ZStack {
            AmbientBackground()
            switch model.state {
            case .loading:
                LoadingView()
            case .failed(let message):
                ErrorView(message: message) {
                    Task { await model.load() }
                }
            case .ready:
                ScrollView(.vertical) {
                    TelemetryDashboard(model: model)
                        .padding(.vertical, 12)
                }
                .scrollIndicators(.visible)
            }
        }
        .task {
            if case .loading = model.state {
                await model.load()
            }
        }
    }
}

struct TelemetryDashboard: View {
    @ObservedObject var model: TelemetryViewModel
    @State private var enabledPanels: Set<TelemetryPanel> = [.weather, .lapStats, .stint, .position]

    var body: some View {
        VStack(spacing: 24) {
            HeaderBar(model: model, enabledPanels: $enabledPanels)
            ScrubberCard(model: model)
            ViewThatFits {
                HStack(alignment: .top, spacing: 24) {
                    leftColumn
                    rightColumn
                }
                VStack(spacing: 24) {
                    leftColumn
                    rightColumn
                }
            }
        }
        .padding(32)
    }

    private var leftColumn: some View {
        VStack(spacing: 20) {
            HeroCard(session: model.session)
            SpeedCard(
                speed: model.currentSample?.speed ?? 0,
                accent: driverAccent
            )
            ThrottleBrakeCard(
                throttle: model.currentSample?.throttle ?? 0,
                brake: model.currentSample?.brake ?? 0
            )
        }
    }

    private var rightColumn: some View {
        VStack(spacing: 20) {
            TrackMapCard(
                track: model.trackPoints,
                trail: model.trailPoints,
                current: model.currentLocation.map { CGPoint(x: $0.x, y: $0.y) },
                bounds: model.trackBounds,
                elapsed: model.sessionOffset
            )
            TelemetryExtrasGrid(model: model, enabledPanels: enabledPanels)
            DriveStateCard(
                gear: model.currentSample?.gear ?? 0,
                rpm: model.currentSample?.rpm ?? 0,
                drs: model.currentSample?.drs ?? 0,
                accent: driverAccent
            )
            SpeedHistoryCard(
                speeds: model.speedHistory,
                accent: driverAccent
            )
        }
    }

    private var driverAccent: Color {
        Color(hex: model.driver?.teamColour ?? "", fallback: TelemetryTheme.accentWarm)
    }
}

struct HeaderBar: View {
    @ObservedObject var model: TelemetryViewModel
    @Binding var enabledPanels: Set<TelemetryPanel>
    @State private var showLayers = false

    var body: some View {
        HStack(spacing: 16) {
            DriverBadge(driver: model.driver)
            VStack(alignment: .leading, spacing: 6) {
                Text(model.driver?.fullName ?? "Loading driver")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textPrimary)
                Text(model.driver?.teamName ?? "OpenF1 Telemetry")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                Text(sessionLine)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
            }
            Spacer()
            LivePill(isPlaying: model.isPlaying)
            DriverSelector(model: model)
            Button(action: { showLayers.toggle() }) {
                Image(systemName: "slider.horizontal.3")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(TelemetryTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .popover(isPresented: $showLayers) {
                TelemetryLayersPanel(enabledPanels: $enabledPanels)
                    .frame(minWidth: 240)
                    .padding(16)
            }
            PlaybackControls(model: model)
        }
        .padding(.horizontal, 4)
    }

    private var sessionLine: String {
        guard let session = model.session else {
            return "OpenF1 replay telemetry"
        }
        return "\(session.location) - \(session.sessionName) - \(session.year)"
    }
}

struct DriverBadge: View {
    let driver: DriverInfo?

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.7))
            if let urlString = driver?.headshotURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(TelemetryTheme.textSecondary)
            }
        }
        .frame(width: 56, height: 56)
        .overlay(
            Circle()
                .strokeBorder(
                    Color(hex: driver?.teamColour ?? "", fallback: TelemetryTheme.accentWarm),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct LivePill: View {
    let isPlaying: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPlaying ? Color.red : TelemetryTheme.textSecondary)
                .frame(width: 8, height: 8)
                .scaleEffect(isPlaying && pulse ? 1.3 : 0.8)
                .opacity(isPlaying && pulse ? 1 : 0.6)
            Text(isPlaying ? "LIVE REPLAY" : "PAUSED")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}

struct PlaybackControls: View {
    @ObservedObject var model: TelemetryViewModel

    var body: some View {
        HStack(spacing: 10) {
            Button(action: model.togglePlayback) {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: model.restartPlayback) {
                Image(systemName: "backward.end.fill")
            }
            Menu {
                Button("0.8x") { model.playbackRate = 0.8 }
                Button("1.0x") { model.playbackRate = 1.0 }
                Button("1.35x") { model.playbackRate = 1.35 }
                Button("1.75x") { model.playbackRate = 1.75 }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                    Text("\(model.playbackRate, specifier: "%.2g")x")
                }
            }
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(TelemetryTheme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct ScrubberCard: View {
    @ObservedObject var model: TelemetryViewModel
    @State private var isScrubbing = false
    @State private var scrubValue = 0.0
    @State private var wasPlaying = false

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Session Timeline")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    Spacer()
                    Text(timeLabel)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { isScrubbing ? scrubValue : model.playbackProgress },
                        set: { newValue in
                            scrubValue = newValue
                            if isScrubbing {
                                model.seek(toProgress: newValue)
                            }
                        }
                    ),
                    in: 0...1,
                    onEditingChanged: handleEditingChanged
                )
                .tint(TelemetryTheme.accentCool)
                .disabled(model.duration <= 0)
            }
        }
        .onAppear {
            scrubValue = model.playbackProgress
        }
        .onChange(of: model.sessionOffset) { _ in
            if !isScrubbing {
                scrubValue = model.playbackProgress
            }
        }
    }

    private var timeLabel: String {
        let elapsed = TimeFormatter.string(from: model.sessionOffset)
        let total = TimeFormatter.string(from: model.duration)
        return "T+\(elapsed) / \(total)"
    }

    private func handleEditingChanged(_ isEditing: Bool) {
        isScrubbing = isEditing
        if isEditing {
            scrubValue = model.playbackProgress
            wasPlaying = model.isPlaying
            if wasPlaying {
                model.isPlaying = false
            }
        } else {
            model.seek(toProgress: scrubValue)
            if wasPlaying {
                model.isPlaying = true
            }
        }
    }
}

struct DriverSelector: View {
    @ObservedObject var model: TelemetryViewModel

    var body: some View {
        Menu {
            ForEach(model.drivers) { driver in
                Button(action: { model.selectDriver(driver) }) {
                    HStack {
                        Text("#\(driver.driverNumber)")
                            .monospacedDigit()
                        Text(driver.fullName)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(model.driver?.nameAcronym ?? "DRV")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(TelemetryTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(driverAccent.opacity(0.5), lineWidth: 1)
            )
        }
        .disabled(model.drivers.isEmpty)
    }

    private var driverAccent: Color {
        Color(hex: model.driver?.teamColour ?? "", fallback: TelemetryTheme.accentWarm)
    }
}

struct TelemetryLayersPanel: View {
    @Binding var enabledPanels: Set<TelemetryPanel>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Telemetry Layers")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textPrimary)
            ForEach(TelemetryPanel.allCases) { panel in
                Toggle(isOn: binding(for: panel)) {
                    Label(panel.title, systemImage: panel.icon)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textPrimary)
                }
            }
        }
    }

    private func binding(for panel: TelemetryPanel) -> Binding<Bool> {
        Binding(
            get: { enabledPanels.contains(panel) },
            set: { isOn in
                if isOn {
                    enabledPanels.insert(panel)
                } else {
                    enabledPanels.remove(panel)
                }
            }
        )
    }
}

enum TelemetryPanel: String, CaseIterable, Identifiable {
    case weather
    case lapStats
    case stint
    case pit
    case position
    case intervals
    case raceControl
    case teamRadio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weather: return "Weather"
        case .lapStats: return "Lap Stats"
        case .stint: return "Stint"
        case .pit: return "Pit"
        case .position: return "Position"
        case .intervals: return "Intervals"
        case .raceControl: return "Race Control"
        case .teamRadio: return "Team Radio"
        }
    }

    var icon: String {
        switch self {
        case .weather: return "cloud.sun"
        case .lapStats: return "stopwatch"
        case .stint: return "circle.dashed"
        case .pit: return "wrench.and.screwdriver"
        case .position: return "list.number"
        case .intervals: return "arrow.left.and.right"
        case .raceControl: return "flag.checkered"
        case .teamRadio: return "waveform"
        }
    }
}

struct HeroCard: View {
    let session: SessionInfo?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Formula Vision")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textPrimary)
                    Spacer()
                    Text("OPENF1")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
                FormulaVisionLogo()
                    .frame(height: 160)
                    .padding(.vertical, 4)
                Text(sessionLine)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                Text("Telemetry overlay tuned for Vision Pro.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
            }
        }
    }

    private var sessionLine: String {
        guard let session else {
            return "Singapore 2023 practice replay"
        }
        return "\(session.countryName) - \(session.circuitShortName) - \(session.sessionName)"
    }
}

struct FormulaVisionLogo: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            TelemetryTheme.accentCool.opacity(0.2),
                            TelemetryTheme.accentWarm.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                )
            HStack(spacing: 24) {
                AppleTVMark()
                Capsule()
                    .fill(.white.opacity(0.6))
                    .frame(width: 2, height: 56)
                F1Mark()
            }
            .padding(.horizontal, 24)
        }
    }
}

struct AppleTVMark: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "applelogo")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(TelemetryTheme.textPrimary)
            Text("tv+")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.white.opacity(0.65))
        )
        .overlay(
            Capsule()
                .strokeBorder(.black.opacity(0.08), lineWidth: 1)
        )
    }
}

struct F1Mark: View {
    var body: some View {
        HStack(spacing: 12) {
            SpeedStreaks()
            HStack(spacing: 0) {
                Text("F")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .italic()
                    .foregroundStyle(TelemetryTheme.textPrimary)
                Text("1")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .italic()
                    .foregroundStyle(TelemetryTheme.accentWarm)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.35), lineWidth: 1)
        )
    }
}

struct SpeedStreaks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(streakGradient)
                .frame(width: 44, height: 6)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(streakGradient)
                .frame(width: 32, height: 6)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(streakGradient)
                .frame(width: 20, height: 6)
        }
    }

    private var streakGradient: LinearGradient {
        LinearGradient(
            colors: [TelemetryTheme.accentWarm, TelemetryTheme.accentCool],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct SpeedCard: View {
    let speed: Double
    let accent: Color

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Speed")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(speed))")
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(TelemetryTheme.textPrimary)
                    Text("km/h")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
                GaugeBar(value: speed, maxValue: 340, accent: accent)
            }
        }
    }
}

struct ThrottleBrakeCard: View {
    let throttle: Double
    let brake: Double

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Controls")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                BarGauge(label: "Throttle", value: throttle, accent: TelemetryTheme.accentCool)
                BarGauge(label: "Brake", value: brake, accent: TelemetryTheme.accentWarm)
            }
        }
    }
}

struct DriveStateCard: View {
    let gear: Int
    let rpm: Double
    let drs: Int
    let accent: Color

    var body: some View {
        TelemetryCard {
            HStack(spacing: 20) {
                MetricBlock(title: "Gear", value: gearText)
                Divider()
                MetricBlock(title: "RPM", value: "\(Int(rpm))")
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("DRS")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    Text(drs > 0 ? "OPEN" : "CLOSED")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(drs > 0 ? accent : TelemetryTheme.textPrimary)
                }
            }
        }
        .frame(height: 96)
    }

    private var gearText: String {
        if gear == 0 { return "N" }
        if gear == -1 { return "R" }
        return "\(gear)"
    }
}

struct TrackMapCard: View {
    let track: [CGPoint]
    let trail: [CGPoint]
    let current: CGPoint?
    let bounds: TrackBounds
    let elapsed: TimeInterval

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Track Map")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    Spacer()
                    Text("T+\(TimeFormatter.string(from: elapsed))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
                TrackMapView(track: track, trail: trail, current: current, bounds: bounds)
                    .frame(height: 240)
            }
        }
    }
}

struct SpeedHistoryCard: View {
    let speeds: [Double]
    let accent: Color

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Speed Trace")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    Spacer()
                    Text("Recent")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
                SpeedHistoryView(speeds: speeds, accent: accent)
                    .frame(height: 120)
            }
        }
    }
}

struct TelemetryExtrasGrid: View {
    @ObservedObject var model: TelemetryViewModel
    let enabledPanels: Set<TelemetryPanel>

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        let panels = TelemetryPanel.allCases.filter { enabledPanels.contains($0) }
        if panels.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(panels) { panel in
                    extraCard(for: panel)
                }
            }
        }
    }

    @ViewBuilder
    private func extraCard(for panel: TelemetryPanel) -> some View {
        switch panel {
        case .weather:
            WeatherCard(weather: model.currentWeather)
        case .lapStats:
            LapStatsCard(
                lap: model.currentLap,
                lastLap: model.lastCompletedLapTime,
                bestLap: model.bestLapTime
            )
        case .stint:
            StintCard(stint: model.currentStint)
        case .pit:
            PitCard(pit: model.lastPitStop)
        case .position:
            PositionCard(position: model.currentPosition, totalDrivers: model.drivers.count)
        case .intervals:
            IntervalCard(interval: model.currentInterval)
        case .raceControl:
            RaceControlCard(message: model.latestRaceControl)
                .gridCellColumns(2)
        case .teamRadio:
            TeamRadioCard(radio: model.latestRadio, startDate: model.sessionStart)
                .gridCellColumns(2)
        }
    }
}

struct WeatherCard: View {
    let weather: WeatherSample?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weather")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(spacing: 16) {
                    TelemetryStat(title: "Air", value: metric(weather?.airTemperature, suffix: "C"))
                    TelemetryStat(title: "Track", value: metric(weather?.trackTemperature, suffix: "C"))
                    TelemetryStat(title: "Humidity", value: metric(weather?.humidity, suffix: "%"))
                }
                HStack(spacing: 16) {
                    TelemetryStat(title: "Wind", value: metric(weather?.windSpeed, suffix: "m/s"))
                    TelemetryStat(title: "Dir", value: metric(weather?.windDirection, suffix: "deg"))
                    TelemetryStat(title: "Rain", value: metric(weather?.rainfall, suffix: "mm"))
                }
            }
        }
    }

    private func metric(_ value: Double?, suffix: String) -> String {
        guard let value else { return "--" }
        if suffix == "mm" {
            return String(format: "%.1f%@", value, suffix)
        }
        if suffix == "m/s" {
            return String(format: "%.1f%@", value, suffix)
        }
        return String(format: "%.0f%@", value, suffix)
    }
}

struct LapStatsCard: View {
    let lap: LapSample?
    let lastLap: Double?
    let bestLap: Double?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lap Stats")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(spacing: 16) {
                    TelemetryStat(title: "Lap", value: lapNumberText)
                    TelemetryStat(title: "Last", value: TimeFormatter.lapString(from: lastLap))
                    TelemetryStat(title: "Best", value: TimeFormatter.lapString(from: bestLap))
                }
                HStack(spacing: 16) {
                    TelemetryStat(title: "S1", value: TimeFormatter.lapString(from: lap?.sector1Duration))
                    TelemetryStat(title: "S2", value: TimeFormatter.lapString(from: lap?.sector2Duration))
                    TelemetryStat(title: "S3", value: TimeFormatter.lapString(from: lap?.sector3Duration))
                }
            }
        }
    }

    private var lapNumberText: String {
        guard let lap = lap else { return "--" }
        return "\(lap.lapNumber)"
    }
}

struct StintCard: View {
    let stint: StintSample?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stint")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(spacing: 16) {
                    TelemetryStat(title: "Compound", value: stint?.compound ?? "--")
                    TelemetryStat(title: "Laps", value: lapRange)
                    TelemetryStat(title: "Age", value: stintAge)
                }
            }
        }
    }

    private var lapRange: String {
        guard let stint = stint else { return "--" }
        if let lapEnd = stint.lapEnd {
            return "\(stint.lapStart)-\(lapEnd)"
        }
        return "\(stint.lapStart)-"
    }

    private var stintAge: String {
        guard let age = stint?.tyreAgeAtStart else { return "--" }
        return "\(age)"
    }
}

struct PitCard: View {
    let pit: PitSample?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pit")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(spacing: 16) {
                    TelemetryStat(title: "Lap", value: pitLap)
                    TelemetryStat(title: "Duration", value: TimeFormatter.lapString(from: pit?.pitDuration))
                }
            }
        }
    }

    private var pitLap: String {
        guard let pit = pit else { return "--" }
        return "\(pit.lapNumber)"
    }
}

struct PositionCard: View {
    let position: PositionSample?
    let totalDrivers: Int

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Position")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(spacing: 16) {
                    TelemetryStat(title: "Current", value: positionText)
                    TelemetryStat(title: "Field", value: totalDrivers > 0 ? "\(totalDrivers)" : "--")
                }
            }
        }
    }

    private var positionText: String {
        guard let position = position else { return "--" }
        return "P\(position.position)"
    }
}

struct IntervalCard: View {
    let interval: IntervalSample?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Intervals")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                HStack(spacing: 16) {
                    TelemetryStat(title: "To Leader", value: gapText(interval?.gapToLeader))
                    TelemetryStat(title: "Interval", value: gapText(interval?.interval))
                }
            }
        }
    }

    private func gapText(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "+%.3f", value)
    }
}

struct RaceControlCard: View {
    let message: RaceControlMessage?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Race Control")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    Spacer()
                    Text(message?.category ?? "--")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
                Text(message?.message ?? "No recent notices.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textPrimary)
                    .lineLimit(3)
            }
        }
    }
}

struct TeamRadioCard: View {
    let radio: TeamRadioSample?
    let startDate: Date?

    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Team Radio")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                    Spacer()
                    Text("Clip")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(TelemetryTheme.textSecondary)
                }
                Text(radioLabel)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textPrimary)
                    .lineLimit(2)
            }
        }
    }

    private var radioLabel: String {
        guard let radio else { return "No radio clips yet." }
        if let startDate {
            let offset = radio.date.timeIntervalSince(startDate)
            return "Latest at T+\(TimeFormatter.string(from: offset))"
        }
        return "Latest at \(TimeFormatter.clockString(from: radio.date))"
    }
}

struct TelemetryStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textPrimary)
                .monospacedDigit()
        }
    }
}

struct TrackMapView: View {
    let track: [CGPoint]
    let trail: [CGPoint]
    let current: CGPoint?
    let bounds: TrackBounds

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard track.count > 1 else { return }
                let trackPath = path(from: track, size: size)
                context.stroke(trackPath, with: .color(TelemetryTheme.textSecondary.opacity(0.3)), lineWidth: 1.2)

                if trail.count > 1 {
                    let trailPath = path(from: trail, size: size)
                    context.stroke(trailPath, with: .linearGradient(
                        Gradient(colors: [TelemetryTheme.accentCool, TelemetryTheme.accentWarm]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    ), lineWidth: 3)
                }

                if let current {
                    let point = project(current, in: size)
                    let glow = Path(ellipseIn: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
                    context.fill(glow, with: .color(TelemetryTheme.accentWarm.opacity(0.3)))
                    let dot = Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
                    context.fill(dot, with: .color(TelemetryTheme.accentWarm))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.35))
        )
    }

    private func path(from points: [CGPoint], size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: project(first, in: size))
        for point in points.dropFirst() {
            path.addLine(to: project(point, in: size))
        }
        return path
    }

    private func project(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let rangeX = max(bounds.maxX - bounds.minX, 1)
        let rangeY = max(bounds.maxY - bounds.minY, 1)
        let inset: CGFloat = 16
        let usableWidth = size.width - inset * 2
        let usableHeight = size.height - inset * 2
        let scale = min(usableWidth / rangeX, usableHeight / rangeY)
        let scaledWidth = rangeX * scale
        let scaledHeight = rangeY * scale
        let offsetX = (size.width - scaledWidth) / 2
        let offsetY = (size.height - scaledHeight) / 2
        let x = (point.x - bounds.minX) * scale + offsetX
        let y = (point.y - bounds.minY) * scale + offsetY
        return CGPoint(x: x, y: size.height - y)
    }
}

struct SpeedHistoryView: View {
    let speeds: [Double]
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard speeds.count > 1 else { return }
                let maxValue = max(speeds.max() ?? 1, 1)
                let step = size.width / CGFloat(max(speeds.count - 1, 1))
                var path = Path()
                for (index, speed) in speeds.enumerated() {
                    let x = CGFloat(index) * step
                    let y = size.height - (CGFloat(speed) / CGFloat(maxValue)) * size.height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                context.stroke(path, with: .color(accent), lineWidth: 3)

                let lastIndex = speeds.count - 1
                let lastX = CGFloat(lastIndex) * step
                let lastY = size.height - (CGFloat(speeds[lastIndex]) / CGFloat(maxValue)) * size.height
                let highlight = Path(ellipseIn: CGRect(x: lastX - 6, y: lastY - 6, width: 12, height: 12))
                context.fill(highlight, with: .color(accent.opacity(0.4)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.4))
        )
    }
}

struct GaugeBar: View {
    let value: Double
    let maxValue: Double
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.black.opacity(0.1))
                Capsule()
                    .fill(accent)
                    .frame(width: geometry.size.width * CGFloat(min(value / maxValue, 1)))
            }
        }
        .frame(height: 10)
    }
}

struct BarGauge: View {
    let label: String
    let value: Double
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(TelemetryTheme.textSecondary)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.black.opacity(0.1))
                    Capsule()
                        .fill(accent)
                        .frame(width: geometry.size.width * CGFloat(min(value / 100, 1)))
                }
            }
            .frame(height: 8)
        }
    }
}

struct MetricBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textPrimary)
                .monospacedDigit()
        }
    }
}

struct TelemetryCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Syncing OpenF1 telemetry...")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(TelemetryTheme.textPrimary)
            Text("Preparing race replay feed.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(TelemetryTheme.textSecondary)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(TelemetryTheme.accentWarm)
            Text(message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(TelemetryTheme.textPrimary)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.92),
                    Color(red: 0.86, green: 0.92, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(TelemetryTheme.accentWarm.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -220, y: -160)
            Circle()
                .fill(TelemetryTheme.accentCool.opacity(0.35))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: 240, y: 180)
            CircuitGrid()
        }
        .ignoresSafeArea()
    }
}

struct CircuitGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 48
            for x in stride(from: 0, through: size.width, by: spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 1)
        }
    }
}

enum TelemetryTheme {
    static let accentWarm = Color(red: 0.96, green: 0.47, blue: 0.24)
    static let accentCool = Color(red: 0.22, green: 0.56, blue: 0.84)
    static let textPrimary = Color(red: 0.15, green: 0.16, blue: 0.18)
    static let textSecondary = Color(red: 0.38, green: 0.39, blue: 0.42)
}

enum TimeFormatter {
    private static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    static func string(from interval: TimeInterval) -> String {
        formatter.string(from: interval) ?? "00:00"
    }

    static func lapString(from seconds: Double?) -> String {
        guard let seconds else { return "--" }
        let minutes = Int(seconds) / 60
        let remainder = seconds - Double(minutes * 60)
        return String(format: "%d:%06.3f", minutes, remainder)
    }

    static func clockString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

extension Color {
    init(hex: String, fallback: Color) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if cleaned.count == 6, let value = UInt64(cleaned, radix: 16) {
            let red = Double((value >> 16) & 0xFF) / 255
            let green = Double((value >> 8) & 0xFF) / 255
            let blue = Double(value & 0xFF) / 255
            self.init(red: red, green: green, blue: blue)
        } else {
            self = fallback
        }
    }
}
