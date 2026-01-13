# RidePulse

SwiftUI iOS rider/driver realtime communication app with a lightweight Node.js WebSocket backend (`RidePulseAPI`).

## Features
- SwiftUI + MVVM structure for ride dashboard and live chat.
- Real-time messaging pipeline (mock + pluggable WebSocket client with auto-reconnect/ping).
- Google Maps integration with current location, speed, and heading overlay.
- Always-on location and background audio support with AVAudioSession configuration.
- Permissions manager for mic + location and lifecycle handling.
- Node.js TypeScript WebSocket server with room-based presence, leader assignment, heartbeat/pong, chat broadcast.

## Repo layout
- `RidePulse/` — iOS app
  - `App/` app environment, theme, app delegate (Google Maps init)
  - `Core/` models, services, networking (`WebSocketClient`), permissions, audio
  - `Features/` Chat, RideDashboard, Map components
- `RidePulseAPI/` — Node.js WebSocket backend (TypeScript)
- `RidePulseTests/`, `RidePulseUITests/` — test targets

## iOS app setup
1) Open `RidePulse.xcodeproj` in Xcode 15+.
2) Add Google Maps SDK via Swift Package Manager (official Google Maps iOS package) and select `GoogleMaps`.
3) Provide API key:
   - Set scheme Run environment variable `GOOGLE_MAPS_API_KEY=<your_key>` or replace the placeholder in `App/AppDelegate.swift`.
4) Build & run:
   - Simulator: choose an iPhone simulator, `Cmd+R`.
   - Device: select your device, ensure Signing team is set, enable Developer Mode on device.
5) Permissions:
   - App will request location (When In Use → Always) and microphone; accept for full functionality.

## Backend (RidePulseAPI) setup
```bash
cd RidePulseAPI
npm install
npm run dev   # starts ws://localhost:8080
```
Features:
- Room join with leader assignment.
- Presence broadcast with leader/member roles.
- Heartbeat (`heartbeat` → `pong`), idle pruning after 30s.
- Chat broadcast per room.

## iOS ↔ Backend wiring
- Use `WebSocketClient` at `RidePulse/Core/Networking/WebSocketClient.swift`.
- Point to your server URL, e.g. on device: `ws://<your_machine_ip>:8080`.
- Client auto-reconnects with jittered backoff, pings every 15s, and surfaces events: `.connected`, `.disconnected`, `.text`, `.message`, `.error`.

## Background behaviors
- Audio: `AudioSessionConfig` sets `.playAndRecord`, ducks/pauses others, keeps session active on scene changes.
- Location: `AppPermissions` requests Always, allows background updates, and restarts updates on lifecycle transitions.
- Map overlay shows speed (km/h) and heading; location throttled to ~5s updates.

## Testing checklist (quick)
- Clean build, run on real device with permissions granted.
- Background/lock test: verify location + audio stay active for several minutes.
- Reconnect test: kill backend, observe client reconnect; restart backend, messages resume.
- Interruption test: simulate call/Siri → app resumes audio session and location updates.
- Maps: verify current location renders and My Location button works.

## Scripts
- Backend dev server: `npm run dev` (from `RidePulseAPI`).

## Notes
- Update Info.plist strings and API key before distributing.
- For App Store, include user-facing explanation for background location usage.

