import SwiftUI
import CoreLocation
import CoreMotion
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()

    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var altitude: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var accuracy: Double = 0.0
    @Published var heading: Double = 0.0
    @Published var mapCameraPosition: MapCameraPosition = .automatic
    @Published var isFollowingUser = true
    @Published var visibleHorizontalKm: Double = 0
    var cameraDistance: Double = 500
    private var lastCenteredCoordinate: CLLocationCoordinate2D?

    @Published var yaw: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0

    @Published var utcTime: String = ""

    private var timer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        startMotionUpdates()
        startUTCTimeUpdates()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMotionUpdates() {
        motionManager.deviceMotionUpdateInterval = 0.1
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let motion = motion else { return }
                self?.yaw = motion.attitude.yaw * 180 / .pi
                self?.pitch = motion.attitude.pitch * 180 / .pi
                self?.roll = motion.attitude.roll * 180 / .pi
            }
        }
    }

    private func startUTCTimeUpdates() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.utcTime = formatter.string(from: Date())
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        latitude = loc.coordinate.latitude
        longitude = loc.coordinate.longitude
        altitude = loc.altitude
        speed = loc.speed >= 0 ? loc.speed : 0
        accuracy = loc.horizontalAccuracy

        if isFollowingUser {
            lastCenteredCoordinate = loc.coordinate
            mapCameraPosition = .camera(MapCamera(centerCoordinate: loc.coordinate, distance: cameraDistance))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let newWholeHeading = Int((newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading).rounded())
        if Int(heading) != newWholeHeading {
            heading = Double(newWholeHeading)
        }
    }

    func handleCameraChange(center: CLLocationCoordinate2D, distance: Double, region: MKCoordinateRegion) {
        cameraDistance = distance

        let metersPerDegree = 111_320.0
        let horizontalMeters = region.span.longitudeDelta * metersPerDegree * cos(region.center.latitude * .pi / 180)
        visibleHorizontalKm = horizontalMeters / 1000

        guard isFollowingUser, let lastCenter = lastCenteredCoordinate else { return }

        let lastLoc = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
        let camLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)

        if lastLoc.distance(from: camLoc) > max(distance * 0.05, 5) {
            isFollowingUser = false
        }
    }

    func recenter() {
        isFollowingUser = true
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        lastCenteredCoordinate = coord
        mapCameraPosition = .camera(MapCamera(centerCoordinate: coord, distance: cameraDistance))
    }
}
