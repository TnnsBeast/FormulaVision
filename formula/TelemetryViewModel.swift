import Foundation
import CoreGraphics
import Combine

struct SessionInfo: Decodable, Sendable {
    let meetingKey: Int
    let sessionKey: Int
    let location: String
    let sessionName: String
    let countryName: String
    let circuitShortName: String
    let dateStart: Date
    let dateEnd: Date
    let year: Int

    enum CodingKeys: String, CodingKey {
        case meetingKey = "meeting_key"
        case sessionKey = "session_key"
        case location
        case sessionName = "session_name"
        case countryName = "country_name"
        case circuitShortName = "circuit_short_name"
        case dateStart = "date_start"
        case dateEnd = "date_end"
        case year
    }
}

struct DriverInfo: Decodable, Identifiable, Sendable {
    let driverNumber: Int
    let fullName: String
    let nameAcronym: String
    let teamName: String
    let teamColour: String
    let headshotURL: String?

    var id: Int { driverNumber }

    enum CodingKeys: String, CodingKey {
        case driverNumber = "driver_number"
        case fullName = "full_name"
        case nameAcronym = "name_acronym"
        case teamName = "team_name"
        case teamColour = "team_colour"
        case headshotURL = "headshot_url"
    }
}

struct CarSample: Decodable, Sendable {
    let date: Date
    let speed: Double
    let throttle: Double
    let brake: Double
    let rpm: Double
    let gear: Int
    let drs: Int

    enum CodingKeys: String, CodingKey {
        case date
        case speed
        case throttle
        case brake
        case rpm
        case gear = "n_gear"
        case drs
    }
}

struct LocationSample: Decodable, Sendable {
    let date: Date
    let x: Double
    let y: Double
    let z: Double
}

struct PositionSample: Decodable, Sendable {
    let date: Date
    let position: Int
    let driverNumber: Int

    enum CodingKeys: String, CodingKey {
        case date
        case position
        case driverNumber = "driver_number"
    }
}

struct LapSample: Decodable, Sendable {
    let lapNumber: Int
    let dateStart: Date?
    let lapDuration: Double?
    let sector1Duration: Double?
    let sector2Duration: Double?
    let sector3Duration: Double?
    let speedI1: Int?
    let speedI2: Int?
    let speedST: Int?
    let isPitOutLap: Bool?

    enum CodingKeys: String, CodingKey {
        case lapNumber = "lap_number"
        case dateStart = "date_start"
        case lapDuration = "lap_duration"
        case sector1Duration = "duration_sector_1"
        case sector2Duration = "duration_sector_2"
        case sector3Duration = "duration_sector_3"
        case speedI1 = "i1_speed"
        case speedI2 = "i2_speed"
        case speedST = "st_speed"
        case isPitOutLap = "is_pit_out_lap"
    }
}

struct StintSample: Decodable, Sendable {
    let stintNumber: Int
    let lapStart: Int
    let lapEnd: Int?
    let compound: String
    let tyreAgeAtStart: Int?

    enum CodingKeys: String, CodingKey {
        case stintNumber = "stint_number"
        case lapStart = "lap_start"
        case lapEnd = "lap_end"
        case compound
        case tyreAgeAtStart = "tyre_age_at_start"
    }
}

struct PitSample: Decodable, Sendable {
    let date: Date
    let lapNumber: Int
    let pitDuration: Double?

    enum CodingKeys: String, CodingKey {
        case date
        case lapNumber = "lap_number"
        case pitDuration = "pit_duration"
    }
}

struct WeatherSample: Decodable, Sendable {
    let date: Date
    let airTemperature: Double?
    let trackTemperature: Double?
    let humidity: Double?
    let pressure: Double?
    let rainfall: Double?
    let windSpeed: Double?
    let windDirection: Double?

    enum CodingKeys: String, CodingKey {
        case date
        case airTemperature = "air_temperature"
        case trackTemperature = "track_temperature"
        case humidity
        case pressure
        case rainfall
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
    }
}

struct RaceControlMessage: Decodable, Sendable {
    let date: Date
    let driverNumber: Int?
    let lapNumber: Int?
    let category: String
    let flag: String?
    let scope: String?
    let sector: Int?
    let message: String

    enum CodingKeys: String, CodingKey {
        case date
        case driverNumber = "driver_number"
        case lapNumber = "lap_number"
        case category
        case flag
        case scope
        case sector
        case message
    }
}

struct TeamRadioSample: Decodable, Sendable {
    let date: Date
    let recordingURL: String

    enum CodingKeys: String, CodingKey {
        case date
        case recordingURL = "recording_url"
    }
}

struct IntervalSample: Decodable, Sendable {
    let date: Date
    let gapToLeader: Double?
    let interval: Double?
    let driverNumber: Int

    enum CodingKeys: String, CodingKey {
        case date
        case gapToLeader = "gap_to_leader"
        case interval
        case driverNumber = "driver_number"
    }
}

struct TrackBounds: Sendable {
    let minX: Double
    let maxX: Double
    let minY: Double
    let maxY: Double

    static let zero = TrackBounds(minX: 0, maxX: 1, minY: 0, maxY: 1)

    init(minX: Double, maxX: Double, minY: Double, maxY: Double) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    init(points: [LocationSample]) {
        guard let first = points.first else {
            self = TrackBounds(minX: 0, maxX: 1, minY: 0, maxY: 1)
            return
        }

        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }
}

struct TelemetryPreset: Sendable {
    let sessionKey: Int
    let telemetrySessionKey: Int
    let driverNumber: Int
    let label: String
    let subtitle: String

    static let singaporeRace = TelemetryPreset(
        sessionKey: 9165,
        telemetrySessionKey: 9158,
        driverNumber: 1,
        label: "Singapore 2023",
        subtitle: "Race - Replay"
    )
}

struct OpenF1Client: Sendable {
    private let baseURL = URL(string: "https://api.openf1.org/v1")!

    func fetchArray<T: Decodable>(_ path: String, queryItems: [URLQueryItem]) async throws -> [T] {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        let url = components.url!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder.openF1()
        return try decoder.decode([T].self, from: data)
    }

    func fetchSession(sessionKey: Int) async throws -> SessionInfo? {
        let sessions: [SessionInfo] = try await fetchArray(
            "sessions",
            queryItems: [URLQueryItem(name: "session_key", value: String(sessionKey))]
        )
        return sessions.first
    }

    func fetchDrivers(sessionKey: Int) async throws -> [DriverInfo] {
        try await fetchArray(
            "drivers",
            queryItems: [URLQueryItem(name: "session_key", value: String(sessionKey))]
        )
    }

    func fetchCarData(sessionKey: Int, driverNumber: Int) async throws -> [CarSample] {
        try await fetchArray(
            "car_data",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchLocation(sessionKey: Int, driverNumber: Int) async throws -> [LocationSample] {
        try await fetchArray(
            "location",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchPositions(sessionKey: Int, driverNumber: Int) async throws -> [PositionSample] {
        try await fetchArray(
            "position",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchLaps(sessionKey: Int, driverNumber: Int) async throws -> [LapSample] {
        try await fetchArray(
            "laps",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchStints(sessionKey: Int, driverNumber: Int) async throws -> [StintSample] {
        try await fetchArray(
            "stints",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchPitStops(sessionKey: Int, driverNumber: Int) async throws -> [PitSample] {
        try await fetchArray(
            "pit",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchWeather(sessionKey: Int) async throws -> [WeatherSample] {
        try await fetchArray(
            "weather",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey))
            ]
        )
    }

    func fetchRaceControl(sessionKey: Int) async throws -> [RaceControlMessage] {
        try await fetchArray(
            "race_control",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey))
            ]
        )
    }

    func fetchTeamRadio(sessionKey: Int, driverNumber: Int) async throws -> [TeamRadioSample] {
        try await fetchArray(
            "team_radio",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }

    func fetchIntervals(sessionKey: Int, driverNumber: Int) async throws -> [IntervalSample] {
        try await fetchArray(
            "intervals",
            queryItems: [
                URLQueryItem(name: "session_key", value: String(sessionKey)),
                URLQueryItem(name: "driver_number", value: String(driverNumber))
            ]
        )
    }
}

@MainActor
final class TelemetryViewModel: ObservableObject {
    private struct TelemetryLoadResult: Sendable {
        let session: SessionInfo?
        let drivers: [DriverInfo]
        let driver: DriverInfo?
        let selectedDriverNumber: Int
        let carSamples: [CarSample]
        let locationSamples: [LocationSample]
        let positionSamples: [PositionSample]
        let lapSamples: [LapSample]
        let stintSamples: [StintSample]
        let pitSamples: [PitSample]
        let weatherSamples: [WeatherSample]
        let raceControlMessages: [RaceControlMessage]
        let teamRadioSamples: [TeamRadioSample]
        let intervalSamples: [IntervalSample]
        let trackBounds: TrackBounds
        let trackPoints: [CGPoint]
        let baseDate: Date?
        let endDate: Date?
        let bestLapTime: Double?
    }
    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var session: SessionInfo?
    @Published private(set) var drivers: [DriverInfo] = []
    @Published private(set) var driver: DriverInfo?
    @Published private(set) var selectedDriverNumber: Int
    @Published private(set) var sessionStart: Date?
    @Published private(set) var currentPosition: PositionSample?
    @Published private(set) var currentLap: LapSample?
    @Published private(set) var currentStint: StintSample?
    @Published private(set) var lastPitStop: PitSample?
    @Published private(set) var currentWeather: WeatherSample?
    @Published private(set) var latestRaceControl: RaceControlMessage?
    @Published private(set) var latestRadio: TeamRadioSample?
    @Published private(set) var currentInterval: IntervalSample?
    @Published private(set) var bestLapTime: Double?
    @Published private(set) var lastCompletedLapTime: Double?
    @Published private(set) var currentSample: CarSample?
    @Published private(set) var currentLocation: LocationSample?
    @Published private(set) var trackBounds: TrackBounds = .zero
    @Published private(set) var trackPoints: [CGPoint] = []
    @Published private(set) var trailPoints: [CGPoint] = []
    @Published private(set) var speedHistory: [Double] = []
    @Published private(set) var sessionOffset: TimeInterval = 0

    @Published var playbackRate: Double = 1.35
    @Published var isPlaying: Bool = true

    private let preset: TelemetryPreset
    private var carSamples: [CarSample] = []
    private var locationSamples: [LocationSample] = []
    private var positionSamples: [PositionSample] = []
    private var lapSamples: [LapSample] = []
    private var stintSamples: [StintSample] = []
    private var pitSamples: [PitSample] = []
    private var weatherSamples: [WeatherSample] = []
    private var raceControlMessages: [RaceControlMessage] = []
    private var teamRadioSamples: [TeamRadioSample] = []
    private var intervalSamples: [IntervalSample] = []
    private var playbackTask: Task<Void, Never>?

    private var playbackClock: TimeInterval = 0
    private var lastTick: Date?
    private var baseDate: Date?
    private var endDate: Date?
    private var carIndex = 0
    private var locationIndex = 0
    private var lastCarIndex = -1
    private var lastLocationIndex = -1
    private var positionIndex = 0
    private var lastPositionIndex = -1
    private var lapIndex = 0
    private var lastLapIndex = -1
    private var pitIndex = 0
    private var lastPitIndex = -1
    private var weatherIndex = 0
    private var lastWeatherIndex = -1
    private var raceControlIndex = 0
    private var lastRaceControlIndex = -1
    private var teamRadioIndex = 0
    private var lastTeamRadioIndex = -1
    private var intervalIndex = 0
    private var lastIntervalIndex = -1

    init(preset: TelemetryPreset) {
        self.preset = preset
        self.selectedDriverNumber = preset.driverNumber
    }

    convenience init() {
        self.init(preset: TelemetryPreset.singaporeRace)
    }

    deinit {
        playbackTask?.cancel()
    }

    func load(resumeOffset: TimeInterval? = nil) async {
        playbackTask?.cancel()
        state = .loading
        sessionStart = nil

        do {
            let preset = preset
            let selectedNumber = selectedDriverNumber
            let resumeOffset = resumeOffset ?? 0
            let loadResult = try await Task.detached(priority: .userInitiated) {
                let client = OpenF1Client()
                let primarySessionKey = preset.sessionKey
                let telemetrySessionKey = preset.telemetrySessionKey
                let usesTelemetryFallback = primarySessionKey != telemetrySessionKey

                async let sessionTask = client.fetchSession(sessionKey: primarySessionKey)
                async let driversTask = client.fetchDrivers(sessionKey: primarySessionKey)
                async let carTask = client.fetchCarData(sessionKey: telemetrySessionKey, driverNumber: selectedNumber)
                async let locationTask = client.fetchLocation(sessionKey: telemetrySessionKey, driverNumber: selectedNumber)
                async let positionTask = client.fetchPositions(sessionKey: preset.sessionKey, driverNumber: selectedNumber)
                async let lapTask = client.fetchLaps(sessionKey: preset.sessionKey, driverNumber: selectedNumber)
                async let stintTask = client.fetchStints(sessionKey: preset.sessionKey, driverNumber: selectedNumber)
                async let pitTask = client.fetchPitStops(sessionKey: preset.sessionKey, driverNumber: selectedNumber)
                async let weatherTask = client.fetchWeather(sessionKey: preset.sessionKey)
                async let raceControlTask = client.fetchRaceControl(sessionKey: preset.sessionKey)
                async let teamRadioTask = client.fetchTeamRadio(sessionKey: preset.sessionKey, driverNumber: selectedNumber)
                async let intervalTask = client.fetchIntervals(sessionKey: preset.sessionKey, driverNumber: selectedNumber)

                let session = try await sessionTask
                let drivers = try await driversTask.sorted(by: { $0.driverNumber < $1.driverNumber })
                let driver = drivers.first(where: { $0.driverNumber == selectedNumber }) ?? drivers.first
                let resolvedDriverNumber = driver?.driverNumber ?? selectedNumber

                let cars = try await carTask
                let locations = try await locationTask
                let positions = try await positionTask
                let laps = try await lapTask
                let stints = try await stintTask
                let pits = try await pitTask
                let weather = try await weatherTask
                let raceControl = try await raceControlTask
                let teamRadio = try await teamRadioTask
                let intervals = try await intervalTask
                let carSamples = cars.sorted(by: { $0.date < $1.date })
                let locationSamples = locations.sorted(by: { $0.date < $1.date })
                let positionSamples = positions.sorted(by: { $0.date < $1.date })
                let lapSamples = laps
                    .filter { $0.dateStart != nil }
                    .sorted(by: { ($0.dateStart ?? .distantFuture) < ($1.dateStart ?? .distantFuture) })
                let stintSamples = stints.sorted(by: { $0.stintNumber < $1.stintNumber })
                let pitSamples = pits.sorted(by: { $0.date < $1.date })
                let weatherSamples = weather.sorted(by: { $0.date < $1.date })
                let raceControlMessages = raceControl.sorted(by: { $0.date < $1.date })
                let teamRadioSamples = teamRadio.sorted(by: { $0.date < $1.date })
                let intervalSamples = intervals.sorted(by: { $0.date < $1.date })

                let bestLapTime = laps.compactMap { $0.lapDuration }.min()

                let trackBounds = TrackBounds(points: locationSamples)
                let strideValue = max(locationSamples.count / 1400, 1)
                let trackPoints = stride(from: 0, to: locationSamples.count, by: strideValue).map {
                    let point = locationSamples[$0]
                    return CGPoint(x: point.x, y: point.y)
                }

                let baseDate = [carSamples.first?.date, locationSamples.first?.date]
                    .compactMap { $0 }
                    .min()
                let endDate = [carSamples.last?.date, locationSamples.last?.date]
                    .compactMap { $0 }
                    .max()

                let primaryStart = session?.dateStart
                if usesTelemetryFallback, let baseDate, let primaryStart {
                    let shift = baseDate.timeIntervalSince(primaryStart)
                    let shiftDate: (Date) -> Date = { $0.addingTimeInterval(shift) }
                    let shiftOptionalDate: (Date?) -> Date? = { date in
                        guard let date else { return nil }
                        return date.addingTimeInterval(shift)
                    }

                    let shiftedPositions = positionSamples.map {
                        PositionSample(date: shiftDate($0.date), position: $0.position, driverNumber: $0.driverNumber)
                    }
                    let shiftedLaps = lapSamples.map {
                        LapSample(
                            lapNumber: $0.lapNumber,
                            dateStart: shiftOptionalDate($0.dateStart),
                            lapDuration: $0.lapDuration,
                            sector1Duration: $0.sector1Duration,
                            sector2Duration: $0.sector2Duration,
                            sector3Duration: $0.sector3Duration,
                            speedI1: $0.speedI1,
                            speedI2: $0.speedI2,
                            speedST: $0.speedST,
                            isPitOutLap: $0.isPitOutLap
                        )
                    }
                    let shiftedPits = pitSamples.map {
                        PitSample(date: shiftDate($0.date), lapNumber: $0.lapNumber, pitDuration: $0.pitDuration)
                    }
                    let shiftedWeather = weatherSamples.map {
                        WeatherSample(
                            date: shiftDate($0.date),
                            airTemperature: $0.airTemperature,
                            trackTemperature: $0.trackTemperature,
                            humidity: $0.humidity,
                            pressure: $0.pressure,
                            rainfall: $0.rainfall,
                            windSpeed: $0.windSpeed,
                            windDirection: $0.windDirection
                        )
                    }
                    let shiftedRaceControl = raceControlMessages.map {
                        RaceControlMessage(
                            date: shiftDate($0.date),
                            driverNumber: $0.driverNumber,
                            lapNumber: $0.lapNumber,
                            category: $0.category,
                            flag: $0.flag,
                            scope: $0.scope,
                            sector: $0.sector,
                            message: $0.message
                        )
                    }
                    let shiftedRadio = teamRadioSamples.map {
                        TeamRadioSample(date: shiftDate($0.date), recordingURL: $0.recordingURL)
                    }
                    let shiftedIntervals = intervalSamples.map {
                        IntervalSample(
                            date: shiftDate($0.date),
                            gapToLeader: $0.gapToLeader,
                            interval: $0.interval,
                            driverNumber: $0.driverNumber
                        )
                    }

                    return TelemetryLoadResult(
                        session: session,
                        drivers: drivers,
                        driver: driver,
                        selectedDriverNumber: resolvedDriverNumber,
                        carSamples: carSamples,
                        locationSamples: locationSamples,
                        positionSamples: shiftedPositions,
                        lapSamples: shiftedLaps,
                        stintSamples: stintSamples,
                        pitSamples: shiftedPits,
                        weatherSamples: shiftedWeather,
                        raceControlMessages: shiftedRaceControl,
                        teamRadioSamples: shiftedRadio,
                        intervalSamples: shiftedIntervals,
                        trackBounds: trackBounds,
                        trackPoints: trackPoints,
                        baseDate: baseDate,
                        endDate: endDate,
                        bestLapTime: bestLapTime
                    )
                }

                return TelemetryLoadResult(
                    session: session,
                    drivers: drivers,
                    driver: driver,
                    selectedDriverNumber: resolvedDriverNumber,
                    carSamples: carSamples,
                    locationSamples: locationSamples,
                    positionSamples: positionSamples,
                    lapSamples: lapSamples,
                    stintSamples: stintSamples,
                    pitSamples: pitSamples,
                    weatherSamples: weatherSamples,
                    raceControlMessages: raceControlMessages,
                    teamRadioSamples: teamRadioSamples,
                    intervalSamples: intervalSamples,
                    trackBounds: trackBounds,
                    trackPoints: trackPoints,
                    baseDate: baseDate,
                    endDate: endDate,
                    bestLapTime: bestLapTime
                )
            }.value

            session = loadResult.session
            drivers = loadResult.drivers
            driver = loadResult.driver
            selectedDriverNumber = loadResult.selectedDriverNumber
            carSamples = loadResult.carSamples
            locationSamples = loadResult.locationSamples
            positionSamples = loadResult.positionSamples
            lapSamples = loadResult.lapSamples
            stintSamples = loadResult.stintSamples
            pitSamples = loadResult.pitSamples
            weatherSamples = loadResult.weatherSamples
            raceControlMessages = loadResult.raceControlMessages
            teamRadioSamples = loadResult.teamRadioSamples
            intervalSamples = loadResult.intervalSamples
            bestLapTime = loadResult.bestLapTime
            trackBounds = loadResult.trackBounds
            trackPoints = loadResult.trackPoints

            guard let baseDate = loadResult.baseDate,
                  let endDate = loadResult.endDate
            else {
                state = .failed("No telemetry data found for the replay session.")
                return
            }

            self.baseDate = baseDate
            self.endDate = endDate
            sessionStart = baseDate

            playbackClock = 0
            lastTick = nil
            carIndex = 0
            locationIndex = 0
            lastCarIndex = -1
            lastLocationIndex = -1
            positionIndex = 0
            lastPositionIndex = -1
            lapIndex = 0
            lastLapIndex = -1
            pitIndex = 0
            lastPitIndex = -1
            weatherIndex = 0
            lastWeatherIndex = -1
            raceControlIndex = 0
            lastRaceControlIndex = -1
            teamRadioIndex = 0
            lastTeamRadioIndex = -1
            intervalIndex = 0
            lastIntervalIndex = -1
            trailPoints = []
            speedHistory = []
            currentSample = nil
            currentLocation = nil
            currentPosition = nil
            currentLap = nil
            currentStint = nil
            lastPitStop = nil
            currentWeather = nil
            latestRaceControl = nil
            latestRadio = nil
            currentInterval = nil
            lastCompletedLapTime = nil
            sessionOffset = 0

            let initialOffset = min(resumeOffset, duration)
            applySeek(offset: initialOffset)

            state = .ready
            startPlayback()
        } catch {
            state = .failed("OpenF1 request failed. Check your network and try again.")
        }
    }

    var duration: TimeInterval {
        guard let baseDate, let endDate else { return 0 }
        return max(endDate.timeIntervalSince(baseDate), 0)
    }

    var playbackProgress: Double {
        let duration = duration
        guard duration > 0 else { return 0 }
        return min(max(sessionOffset / duration, 0), 1)
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func restartPlayback() {
        guard state == .ready else { return }
        applySeek(offset: 0)
    }

    func seek(toProgress progress: Double) {
        guard state == .ready else { return }
        let duration = duration
        guard duration > 0 else { return }
        let clamped = min(max(progress, 0), 1)
        applySeek(offset: duration * clamped)
    }

    func selectDriver(_ driver: DriverInfo) {
        guard driver.driverNumber != selectedDriverNumber else { return }
        selectedDriverNumber = driver.driverNumber
        let resumeOffset = sessionOffset
        Task { await load(resumeOffset: resumeOffset) }
    }

    private func startPlayback() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.advancePlayback()
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func advancePlayback() {
        guard state == .ready,
              let baseDate,
              let endDate
        else { return }

        let now = Date()
        if let lastTick {
            let delta = now.timeIntervalSince(lastTick)
            if isPlaying {
                playbackClock += delta * playbackRate
            }
        }
        lastTick = now

        let playbackTime = baseDate.addingTimeInterval(playbackClock)
        if playbackTime >= endDate {
            if isPlaying {
                restartPlayback()
            } else {
                playbackClock = duration
                sessionOffset = duration
            }
            return
        }
        sessionOffset = playbackClock

        while carIndex + 1 < carSamples.count && carSamples[carIndex + 1].date <= playbackTime {
            carIndex += 1
        }

        while locationIndex + 1 < locationSamples.count && locationSamples[locationIndex + 1].date <= playbackTime {
            locationIndex += 1
        }

        while positionIndex + 1 < positionSamples.count && positionSamples[positionIndex + 1].date <= playbackTime {
            positionIndex += 1
        }

        while lapIndex + 1 < lapSamples.count,
              let nextLapDate = lapSamples[lapIndex + 1].dateStart,
              nextLapDate <= playbackTime {
            lapIndex += 1
        }

        while pitIndex + 1 < pitSamples.count && pitSamples[pitIndex + 1].date <= playbackTime {
            pitIndex += 1
        }

        while weatherIndex + 1 < weatherSamples.count && weatherSamples[weatherIndex + 1].date <= playbackTime {
            weatherIndex += 1
        }

        while raceControlIndex + 1 < raceControlMessages.count && raceControlMessages[raceControlIndex + 1].date <= playbackTime {
            raceControlIndex += 1
        }

        while teamRadioIndex + 1 < teamRadioSamples.count && teamRadioSamples[teamRadioIndex + 1].date <= playbackTime {
            teamRadioIndex += 1
        }

        while intervalIndex + 1 < intervalSamples.count && intervalSamples[intervalIndex + 1].date <= playbackTime {
            intervalIndex += 1
        }

        if carIndex != lastCarIndex, carIndex < carSamples.count {
            let sample = carSamples[carIndex]
            currentSample = sample
            speedHistory.append(sample.speed)
            if speedHistory.count > 140 {
                speedHistory.removeFirst(speedHistory.count - 140)
            }
            lastCarIndex = carIndex
        }

        if locationIndex != lastLocationIndex, locationIndex < locationSamples.count {
            let location = locationSamples[locationIndex]
            currentLocation = location
            trailPoints.append(CGPoint(x: location.x, y: location.y))
            if trailPoints.count > 200 {
                trailPoints.removeFirst(trailPoints.count - 200)
            }
            lastLocationIndex = locationIndex
        }

        if positionIndex != lastPositionIndex, positionIndex < positionSamples.count {
            currentPosition = positionSamples[positionIndex]
            lastPositionIndex = positionIndex
        }

        if lapIndex != lastLapIndex, lapIndex < lapSamples.count {
            currentLap = lapSamples[lapIndex]
            if let lapDuration = currentLap?.lapDuration {
                lastCompletedLapTime = lapDuration
            }
            lastLapIndex = lapIndex
            updateStint(for: currentLap?.lapNumber)
        }

        if pitIndex != lastPitIndex, pitIndex < pitSamples.count {
            lastPitStop = pitSamples[pitIndex]
            lastPitIndex = pitIndex
        }

        if weatherIndex != lastWeatherIndex, weatherIndex < weatherSamples.count {
            currentWeather = weatherSamples[weatherIndex]
            lastWeatherIndex = weatherIndex
        }

        if raceControlIndex != lastRaceControlIndex, raceControlIndex < raceControlMessages.count {
            latestRaceControl = raceControlMessages[raceControlIndex]
            lastRaceControlIndex = raceControlIndex
        }

        if teamRadioIndex != lastTeamRadioIndex, teamRadioIndex < teamRadioSamples.count {
            latestRadio = teamRadioSamples[teamRadioIndex]
            lastTeamRadioIndex = teamRadioIndex
        }

        if intervalIndex != lastIntervalIndex, intervalIndex < intervalSamples.count {
            currentInterval = intervalSamples[intervalIndex]
            lastIntervalIndex = intervalIndex
        }
    }

    private func applySeek(offset: TimeInterval) {
        guard let baseDate, let endDate else { return }
        let maxOffset = max(endDate.timeIntervalSince(baseDate), 0)
        let clampedOffset = min(max(offset, 0), maxOffset)
        playbackClock = clampedOffset
        sessionOffset = clampedOffset
        lastTick = nil

        let playbackTime = baseDate.addingTimeInterval(clampedOffset)
        carIndex = index(for: playbackTime, in: carSamples, date: { $0.date })
        locationIndex = index(for: playbackTime, in: locationSamples, date: { $0.date })
        positionIndex = index(for: playbackTime, in: positionSamples, date: { $0.date })
        lapIndex = index(for: playbackTime, in: lapSamples, date: { $0.dateStart ?? baseDate })
        pitIndex = index(for: playbackTime, in: pitSamples, date: { $0.date })
        weatherIndex = index(for: playbackTime, in: weatherSamples, date: { $0.date })
        raceControlIndex = index(for: playbackTime, in: raceControlMessages, date: { $0.date })
        teamRadioIndex = index(for: playbackTime, in: teamRadioSamples, date: { $0.date })
        intervalIndex = index(for: playbackTime, in: intervalSamples, date: { $0.date })
        lastCarIndex = carIndex
        lastLocationIndex = locationIndex
        lastPositionIndex = positionIndex
        lastLapIndex = lapIndex
        lastPitIndex = pitIndex
        lastWeatherIndex = weatherIndex
        lastRaceControlIndex = raceControlIndex
        lastTeamRadioIndex = teamRadioIndex
        lastIntervalIndex = intervalIndex
        rebuildState()
    }

    private func rebuildState() {
        if carIndex >= 0 && carIndex < carSamples.count {
            let start = max(carIndex - 140, 0)
            speedHistory = carSamples[start...carIndex].map { $0.speed }
            currentSample = carSamples[carIndex]
        } else {
            speedHistory = []
            currentSample = nil
        }

        if locationIndex >= 0 && locationIndex < locationSamples.count {
            let start = max(locationIndex - 200, 0)
            trailPoints = locationSamples[start...locationIndex].map { CGPoint(x: $0.x, y: $0.y) }
            currentLocation = locationSamples[locationIndex]
        } else {
            trailPoints = []
            currentLocation = nil
        }

        if positionIndex >= 0 && positionIndex < positionSamples.count {
            currentPosition = positionSamples[positionIndex]
        } else {
            currentPosition = nil
        }

        if lapIndex >= 0 && lapIndex < lapSamples.count {
            currentLap = lapSamples[lapIndex]
        } else {
            currentLap = nil
        }

        lastCompletedLapTime = lastCompletedLapDuration(at: lapIndex)
        updateStint(for: currentLap?.lapNumber)

        if pitIndex >= 0 && pitIndex < pitSamples.count {
            lastPitStop = pitSamples[pitIndex]
        } else {
            lastPitStop = nil
        }

        if weatherIndex >= 0 && weatherIndex < weatherSamples.count {
            currentWeather = weatherSamples[weatherIndex]
        } else {
            currentWeather = nil
        }

        if raceControlIndex >= 0 && raceControlIndex < raceControlMessages.count {
            latestRaceControl = raceControlMessages[raceControlIndex]
        } else {
            latestRaceControl = nil
        }

        if teamRadioIndex >= 0 && teamRadioIndex < teamRadioSamples.count {
            latestRadio = teamRadioSamples[teamRadioIndex]
        } else {
            latestRadio = nil
        }

        if intervalIndex >= 0 && intervalIndex < intervalSamples.count {
            currentInterval = intervalSamples[intervalIndex]
        } else {
            currentInterval = nil
        }
    }

    private func updateStint(for lapNumber: Int?) {
        guard let lapNumber else {
            currentStint = nil
            return
        }
        currentStint = stintSamples.first(where: {
            let endLap = $0.lapEnd ?? Int.max
            return lapNumber >= $0.lapStart && lapNumber <= endLap
        })
    }

    private func lastCompletedLapDuration(at index: Int) -> Double? {
        guard !lapSamples.isEmpty, index >= 0 else { return nil }
        let upper = min(index, lapSamples.count - 1)
        for i in stride(from: upper, through: 0, by: -1) {
            if let duration = lapSamples[i].lapDuration {
                return duration
            }
        }
        return nil
    }

    private func index<T>(for time: Date, in samples: [T], date: (T) -> Date) -> Int {
        guard !samples.isEmpty else { return -1 }

        let firstDate = date(samples[0])
        if time <= firstDate {
            return 0
        }

        let lastIndex = samples.count - 1
        let lastDate = date(samples[lastIndex])
        if time >= lastDate {
            return lastIndex
        }

        var low = 0
        var high = lastIndex
        while low <= high {
            let mid = (low + high) / 2
            let midDate = date(samples[mid])
            if midDate == time {
                return mid
            }
            if midDate < time {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return max(high, 0)
    }
}

extension JSONDecoder {
    static func openF1() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
        return decoder
    }
}
