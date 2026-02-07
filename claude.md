# Where - iOS App Overview

## Purpose

Where is a single-screen iOS utility app that acts as a real-time location and device motion dashboard. It displays GPS coordinates, altitude, speed, compass heading with cardinal direction, device orientation (yaw/pitch/roll), UTC time, an interactive map with scale indicator, and orientation gauges. Built entirely in SwiftUI with no external dependencies.

## Repository

GitHub: `https://github.com/pcwilliams/where.git`

## Project Structure

```
Where/
├── Where.xcodeproj/
├── README.md
├── claude.md                   # This file
└── Where/
    ├── WhereApp.swift          # App entry point (17 lines)
    ├── ContentView.swift       # Main (and only) UI view (174 lines)
    ├── LocationManager.swift   # Core data manager for GPS, motion & map camera (114 lines)
    └── Assets.xcassets/
        ├── AppIcon.appiconset/ # Stylized compass icon (standard, dark, tinted PNGs)
        └── AccentColor.colorset/
```

Three Swift source files. No storyboards, no XIBs, no third-party packages.

## Architecture

MVVM with SwiftUI's reactive data binding:

- **LocationManager** (`ObservableObject`) collects data from CoreLocation and CoreMotion, exposing it via `@Published` properties. Also manages map camera state and follow-mode logic.
- **ContentView** observes LocationManager with `@StateObject` and rebuilds the UI automatically when values change.
- **WhereApp** is a minimal `@main` entry point that hosts ContentView in a WindowGroup.

## Source Files

### WhereApp.swift (17 lines)

Standard SwiftUI app entry point. Creates a `WindowGroup` containing `ContentView`.

### LocationManager.swift (114 lines)

Manages all sensor data and map camera state. Conforms to `CLLocationManagerDelegate`.

**Published properties:**

| Property | Type | Source |
|----------|------|--------|
| latitude, longitude | Double | CoreLocation |
| altitude | Double | CoreLocation |
| speed | Double | CoreLocation (clamped to >= 0) |
| accuracy | Double | CoreLocation |
| heading | Double | CoreLocation heading updates |
| mapCameraPosition | MapCameraPosition | Derived from location (when following) |
| isFollowingUser | Bool | Follow-mode flag (default: true) |
| visibleHorizontalKm | Double | Computed from map region span |
| yaw, pitch, roll | Double | CoreMotion (radians converted to degrees) |
| utcTime | String | Timer (1-second interval, HH:mm:ss UTC) |

**Non-published state:**
- `cameraDistance` (Double, default 500) — current map zoom level in meters, preserved across GPS updates
- `lastCenteredCoordinate` (CLLocationCoordinate2D?) — last programmatic camera center, used to detect user panning

**Key methods:**
- `handleCameraChange(center:distance:region:)` — called by `onMapCameraChange`; stores zoom level, computes visible horizontal distance from region span, detects user panning to disable follow mode
- `recenter()` — re-enables follow mode and snaps camera to current user location at current zoom level

**Initialization behavior:**
- Requests "when in use" location authorization
- Starts location updates with `kCLLocationAccuracyBest`
- Starts heading updates with no filtering (`kCLHeadingFilterNone`)
- Starts device motion updates at 10 Hz (0.1s interval)
- Starts a 1-second timer for UTC time

**Cleanup:** Timer is invalidated in `deinit`. Motion closure uses `[weak self]` to avoid retain cycles.

### ContentView.swift (174 lines)

Single-screen UI composed of five sections in a VStack:

1. **GPS Information Grid** — 9 rows showing UTC time, latitude, longitude, altitude, speed (m/s, km/h, mph), heading with 16-point compass direction (e.g. "247° WSW"), and accuracy. Uses monospaced font for numeric values. Coordinates displayed to 6 decimal places (~0.1m precision).

2. **Map Style Picker** — Segmented control selecting between Standard, Satellite, and Hybrid map styles. Selection persisted to UserDefaults via `@AppStorage("mapStyleSelection")`.

3. **Interactive Map** — MapKit `Map` view (iOS 17+ API) in a ZStack with user annotation and configurable style. Fixed height of 300pt with rounded corners. No system map controls (`.mapControls { }` is empty). When the user pans away from their location, a custom blue recenter button (36x36 circle, top-right corner, animated in/out) appears that calls `locationManager.recenter()`. Uses `onMapCameraChange(frequency: .onEnd)` to track zoom level, compute visible distance, and detect panning.

4. **Map Scale Line** — A caption-sized monospaced text below the map showing the visible horizontal distance in dual units. Shows km/miles when zoomed out (e.g. "Visible: 2.4 km / 1.5 mi"), switches to meters/feet when below 1 km.

5. **Orientation Gauges** — Three `Gauge` views (accessoryCircular style) in an HStack for yaw, pitch, and roll. Color-coded: green (<15 degrees), orange (15-45 degrees), red (>45 degrees).

**Helper functions:**
- `row(_:_:)` — builds a GridRow with right-aligned label and left-aligned value
- `compassDirection(_:)` — converts heading degrees to 16-point compass string (N, NNE, NE, ENE, etc.) using 22.5-degree sectors with 11.25-degree offset
- `orientationGauge(_:value:range:)` — builds a color-coded circular gauge with degree label

**Helper types:**
- `MapStyleOption` enum with rawValue Int for standard/satellite/hybrid, with `mapStyle` computed property mapping to MapKit's `MapStyle`

## Frameworks Used

| Framework | Purpose |
|-----------|---------|
| SwiftUI | Entire UI |
| MapKit | Interactive map display, MapCameraPosition |
| CoreLocation | GPS coordinates, altitude, speed, heading |
| CoreMotion | Device orientation (yaw, pitch, roll) |
| Foundation | Timer, DateFormatter |

No networking. No third-party dependencies (no SPM packages, no CocoaPods, no Carthage).

## Permissions

| Permission | Description String |
|------------|-------------------|
| Location When In Use | "We need your location to show coordinates" |

No entitlements file. No background modes, no push notifications.

## Persistence

Only the map style selection is persisted (via `@AppStorage` / UserDefaults, key `"mapStyleSelection"`). All sensor data is transient and not stored.

## Build Configuration

| Setting | Value |
|---------|-------|
| Xcode | 16.4 |
| Swift | 5.0 |
| Deployment Target | iOS 18.5 |
| Bundle Identifier | PW.Where |
| Device Families | iPhone and iPad |
| Marketing Version | 1.0 |
| Code Sign Style | Automatic |
| Development Team | L7GB763YG3 |

Supports portrait and both landscape orientations on iPhone. All orientations on iPad.

## Notable Implementation Details

- **Map follow mode:** The map camera follows the user by default, preserving the current zoom level (`cameraDistance`) across GPS updates. When the user pans away (detected by comparing camera center to last programmatic center, threshold: max of 5% of view distance or 5 meters), follow mode disables and a custom recenter button appears. Zoom level is always preserved regardless of follow mode. The system `MapUserLocationButton` was removed to avoid visual alignment issues at extreme zoom levels.
- **Map scale calculation:** Horizontal visible distance is computed from the map region's `longitudeDelta` adjusted for latitude: `longitudeDelta * 111320 * cos(latitude)` meters. Displayed in km/miles or m/feet depending on scale.
- **Compass direction:** 16-point compass rose computed by dividing heading into 22.5-degree sectors with an 11.25-degree offset for centering.
- **Speed display:** Shows all three unit conversions simultaneously (m/s, km/h via x3.6, mph via x2.23694). Negative speed values from CoreLocation are clamped to 0.
- **Orientation conversion:** CoreMotion provides radians; the app converts to degrees (x 180/pi).
- **UTC time:** Explicitly uses GMT timezone, not local time. Updates every second.
- **Gauge colors:** Provide a visual indicator of how level/tilted the device is — green means nearly flat/upright, red means significantly tilted.
- **Auto-generated Info.plist:** The project uses Xcode's generated Info.plist rather than a manual file. Privacy strings and scene configuration are set in the build settings.
- **App icon:** Stylized compass with dark navy gradient background, silver bezel ring with degree tick marks, red-tipped north needle, silver south needle, smaller east/west needles, N/S/E/W cardinal labels, and silver center cap. Includes standard, dark, and tinted variants at 1024x1024. Generated via Python/Pillow script.
