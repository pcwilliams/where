# Where

A real-time location and device motion dashboard for iOS, built entirely in SwiftUI.

Where displays your GPS coordinates, altitude, speed, compass heading, an interactive map with scale indicator, and device orientation gauges — all updating live on a single screen.

## Features

- **GPS data** — latitude, longitude, altitude, accuracy, and UTC time
- **Speed** — displayed simultaneously in m/s, km/h, and mph
- **Compass heading** — degrees with 16-point cardinal direction (N, NNE, NE, etc.)
- **Interactive map** — standard, satellite, and hybrid styles with pinch-zoom that persists across GPS updates
- **Map scale** — visible horizontal distance shown in km/miles or m/feet
- **Device orientation** — yaw, pitch, and roll gauges with color-coded tilt indicators
- **Follow mode** — map auto-follows your location; pan away to explore freely, tap the recenter button to snap back

## Screenshots

_Coming soon_

## Requirements

- iOS 18.5+
- Xcode 16.4+
- Location permission (when in use)

## Getting Started

```
git clone https://github.com/pcwilliams/where.git
cd where
```

Open `Where.xcodeproj` in Xcode, select your device or simulator, and run.

The app will request location permission on first launch. GPS data and the map require a device with location services enabled.

## Project Structure

```
Where/
├── WhereApp.swift          # App entry point
├── ContentView.swift       # Single-screen UI
├── LocationManager.swift   # GPS, motion, and map camera management
└── Assets.xcassets/        # Compass app icon (standard, dark, tinted)
```

Three Swift files, no storyboards, no third-party dependencies. Uses only Apple frameworks: SwiftUI, MapKit, CoreLocation, CoreMotion.

## Background

This started as a learning project for Swift programming and interaction with the Map and Device APIs. ChatGPT helped with the initial code, and Claude Code helped with later enhancements.

## License

Personal project. No license specified.

## Checking out this repo:
```
git clone https://github.com/pcwilliams/where.git
cd where
git remote set-url origin git@github.com:pcwilliams/where.git
```



