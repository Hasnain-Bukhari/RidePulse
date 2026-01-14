# RidePulse

SwiftUI iOS rider/driver realtime communication app with a lightweight Node.js WebSocket backend (`RidePulseAPI`).

## Features
- SwiftUI + MVVM structure for ride dashboard and live chat.
- Real-time messaging pipeline (mock + pluggable WebSocket client with auto-reconnect/ping).
- Google Maps integration with current location, speed, and heading overlay.
- Always-on location and background audio support with AVAudioSession configuration.
- Permissions manager for mic + location and lifecycle handling.
- Node.js TypeScript WebSocket server with room-based presence, leader assignment, heartbeat/pong, chat broadcast.
- WebRTC scaffolding for future group voice (audio-only manager + signaling messages).
- Live location protocol and relay (WebSocket location messages) plus multi-rider map rendering with animated markers.
- Route planning scaffold: route model/UI, Google Maps preview, WebSocket route sharing, leader-only edits/transfer support on the backend.
- Basic stability UX: chat shows connection errors with retry; WebSocket client auto-reconnects with jittered backoff and ping.

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
- WebRTC signaling (offer/answer/ICE) messages are relayed via the backend; hook them up with `WebRTCAudioManager` when the WebRTC SDK is added.
- Live location: use `LiveLocationProtocol` to encode/decode location updates; map to `RiderLocation` and render with `LiveRidersMapView`.
- Routes: use `RouteShareProtocol` to send/receive route updates; `RoutePlannerView` provides the UI; backend relays `route-set` and leader transfer.

## Stability & Testing notes
- Error/reconnect UX: chat view surfaces connection failures with retry. WebSocket client pings every 15s and retries with exponential backoff + jitter.
- Network edge cases: expect brief drops to reconnect automatically; if fully offline (airplane mode), retry button is shown.
- Battery: location throttled (~5s), background audio session configured; adjust GPS accuracy and intervals for longer rides as needed.
- Long-ride test (2h): run on device with screen off; verify chat reconnects, location updates keep flowing, and audio remains active after interruptions.
- Pre-release sanity: check permissions prompts, Maps API key, WebSocket endpoints, and background modes before TestFlight.

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


