# Formula Vision Telemetry (visionOS)

Formula Vision is a Vision Pro dashboard that replays OpenF1 telemetry as a live-style HUD. It combines high-frequency car data with race session metadata so you can scrub, switch drivers, and toggle telemetry layers without clutter.

## Screenshot
![Formula Vision Dashboard](FormulaVision.png)

## Features
- Live-style replay of OpenF1 telemetry with play/pause and speed controls
- Timeline scrubber for jumping anywhere in the session
- Driver switching with team color accents
- Track map with live trail and speed trace
- Optional telemetry layers (weather, laps, stints, pits, position, intervals, race control, team radio)
- Apple TV+ x F1 hero branding card

## Data Sources
This app uses the OpenF1 API (https://openf1.org) and pulls the following endpoints:
- High-frequency telemetry: `car_data`, `location`
- Session and driver metadata: `sessions`, `drivers`
- Race data layers: `laps`, `stints`, `pit`, `position`, `weather`, `race_control`, `team_radio`, `intervals`

### Race vs Telemetry Sessions
OpenF1 does not always publish `car_data` / `location` for race sessions. To keep the replay smooth, the app uses:
- Race session metadata for the UI and race layers
- Practice session telemetry as a fallback feed

This is configured in `TelemetryPreset` with two session keys:
- `sessionKey`: the race session key (UI + race layers)
- `telemetrySessionKey`: the session that provides `car_data` / `location`

## Getting Started
Requirements:
- Xcode with the visionOS SDK
- Apple Vision Pro Simulator or device

Run:
1. Open `formula.xcodeproj` in Xcode.
2. Select a visionOS simulator or device.
3. Build and run.

## Controls
- Play/Pause: top right controls
- Timeline scrubber: jump to any moment
- Driver menu: switch drivers
- Layers menu: toggle optional telemetry panels

## Configuration
- Default session and telemetry source live in `formula/formula/TelemetryViewModel.swift` under `TelemetryPreset`.
- Change `sessionKey`, `telemetrySessionKey`, or `driverNumber` to point at a different event.

## Project Structure
- `formula/formula/TelemetryViewModel.swift` - OpenF1 fetch, replay clock, telemetry state
- `formula/formula/TelemetryViews.swift` - UI components and dashboard layout
- `formula/formula/ContentView.swift` - root view

## Notes
- OpenF1 endpoints can return empty sets for certain sessions. The UI keeps those panels quiet when no data is available.
- Team radio clips are URLs only; playback is not implemented in-app.

## Attribution
Telemetry data provided by OpenF1 (https://openf1.org).

## Disclaimer
This project is not affiliated with Formula 1, the FIA, Apple, or any teams. All marks are the property of their respective owners.
