import SwiftUI
import MapKit

enum MapStyleOption: Int, CaseIterable, Identifiable {
    case standard
    case satellite
    case hybrid

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }

    static var available: [MapStyleOption] {
        return allCases
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @AppStorage("mapStyleSelection") private var selectedStyleRaw: Int = 0

    private var selectedStyle: MapStyleOption {
        get { MapStyleOption(rawValue: selectedStyleRaw) ?? .standard }
        set { selectedStyleRaw = newValue.rawValue }
    }

    var body: some View {
        VStack(spacing: 16) {

            // MARK: - GPS Info Table
            Grid(horizontalSpacing: 20, verticalSpacing: 8) {
                row("UTC Time", locationManager.utcTime)
                row("Latitude", String(format: "%.6f", locationManager.latitude))
                row("Longitude", String(format: "%.6f", locationManager.longitude))
                row("Altitude", String(format: "%.1f m", locationManager.altitude))

                let speedMS = locationManager.speed
                let speedKPH = speedMS * 3.6
                let speedMPH = speedMS * 2.23694
                row("Speed (m/s)", String(format: "%.1f", speedMS))
                row("Speed (km/h)", String(format: "%.1f", speedKPH))
                row("Speed (mph)", String(format: "%.1f", speedMPH))

                row("Heading", String(format: "%.0f°", locationManager.heading))
                row("Accuracy", String(format: "%.1f m", locationManager.accuracy))
            }
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal)

            // MARK: - Map Style Picker

            Picker("Map Style", selection: $selectedStyleRaw) {
                ForEach(MapStyleOption.available) { style in
                    Text(style.label).tag(style.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)

            // MARK: - Map View
            
            let currentStyle = MapStyleOption(rawValue: selectedStyleRaw)?.mapStyle ?? .standard
            
            Map(position: $locationManager.mapCameraPosition) {
                UserAnnotation()
            }
            .mapStyle(currentStyle)
            .mapControls {
                MapUserLocationButton()
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // MARK: - Orientation Gauges
            Text("Device Orientation")
                .font(.headline)

            HStack {
                orientationGauge("Yaw", value: locationManager.yaw, range: -180...180)
                orientationGauge("Pitch", value: locationManager.pitch, range: -90...90)
                orientationGauge("Roll", value: locationManager.roll, range: -180...180)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Table Row Helper
    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).frame(maxWidth: .infinity, alignment: .trailing)
            Text(value).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Orientation Gauge
    private func orientationGauge(_ label: String, value: Double, range: ClosedRange<Double>) -> some View {
        let absValue = abs(value)
        let color: Color = {
            switch absValue {
            case 0..<15: return .green
            case 15..<45: return .orange
            default: return .red
            }
        }()

        return VStack {
            Gauge(value: value, in: range) {
                Text(label)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(color)
            .frame(width: 80, height: 80)

            Text(String(format: "%.0f°", value))
                .font(.caption)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
