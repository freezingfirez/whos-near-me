import SwiftUI
import MapKit
import CoreLocation

// MARK: - ContentView
struct ContentView: View {
    let userId: String
    @StateObject private var locationManager = LocationManager()
    @State private var isOnline: Bool = true
    @State private var selectedUsers: Set<String> = []
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var invitationReason: String = "Let's hang out!"
    @State private var showingInvitationsSheet = false

    @State private var nearbyUsers: [User] = []
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var radiusKm: Double = 5
    @State private var lastSentLocation: CLLocation? = nil
    @State private var lastSentAt: Date? = nil
    @State private var isFetchingNearby: Bool = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: nearbyUsers) { user in
                    MapAnnotation(coordinate: user.coordinate) {
                        UserAnnotationView(user: user, isSelected: selectedUsers.contains(user.id)) {
                            if selectedUsers.contains(user.id) {
                                selectedUsers.remove(user.id)
                            } else {
                                selectedUsers.insert(user.id)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)

                SlidingPanelView(
                    isOnline: $isOnline,
                    radiusKm: $radiusKm,
                    selectedUsers: $selectedUsers,
                    invitationReason: $invitationReason,
                    onInvite: {
                        sendInvitations(to: Array(selectedUsers), reason: invitationReason)
                        selectedUsers.removeAll()
                    },
                    onInviteAll: {
                        sendInvitations(to: nearbyUsers.map { $0.id }, reason: invitationReason)
                    }
                )
            }
            .navigationBarTitle("Who's Near Me?", displayMode: .inline)
            .navigationBarItems(leading: onlineStatusToggle(), trailing: invitationsButton())
            .sheet(isPresented: $showingInvitationsSheet) {
                InvitationsRootView(userId: userId)
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                // Initial fetch of nearby users
                fetchNearbyUsers()
                updateOnlineStatus(isOnline: isOnline)
                if let coord = locationManager.userLocation?.coordinate {
                    region.center = coord
                }
            }
            .onChange(of: locationManager.userLocation) { newLocation in
                if let location = newLocation {
                    // Keep the map centered on user
                    region.center = location.coordinate
                    if isOnline, shouldSendLocationUpdate(newLocation: location) {
                        updateUserLocation(location: location)
                    }
                }
            }
            .onChange(of: isOnline) { newValue in
                updateOnlineStatus(isOnline: newValue)
            }
            .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
                if isOnline { fetchNearbyUsers() }
            }
        }
    }

    private func onlineStatusToggle() -> some View {
        Toggle(isOn: $isOnline) {
            Text(isOnline ? "Online" : "Offline")
                .font(.subheadline)
                .fontWeight(.light)
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.theme.green))
    }

    private func invitationsButton() -> some View {
        Button(action: {
            showingInvitationsSheet = true
        }) {
            Image(systemName: "envelope.fill")
                .font(.title2)
                .foregroundColor(Color.theme.accent)
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    private func updateUserLocation(location: CLLocation) {
        guard let url = URL(string: "\(API.baseURL)/api/location/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
                return
            }
            // Optionally handle success/failure response
            print("Location updated successfully")
            DispatchQueue.main.async {
                fetchNearbyUsers() // Fetch nearby users after updating location
            }
        }.resume()
    }

    private func fetchNearbyUsers() {
        if isFetchingNearby { return }
        DispatchQueue.main.async {
            isFetchingNearby = true
        }
        let radiusMeters = Int(radiusKm * 1000)
        guard let url = URL(string: "\(API.baseURL)/api/nearby/\(userId)?radius=\(radiusMeters)") else {
            DispatchQueue.main.async { isFetchingNearby = false }
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching nearby users: \(error.localizedDescription)")
                DispatchQueue.main.async { isFetchingNearby = false }
                return
            }

            guard let data = data else {
                print("No data received for nearby users.")
                DispatchQueue.main.async { isFetchingNearby = false }
                return
            }

            do {
                let decodedUsers = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self.nearbyUsers = decodedUsers
                    self.isFetchingNearby = false
                }
            } catch {
                print("Error decoding nearby users: \(error.localizedDescription)")
                DispatchQueue.main.async { isFetchingNearby = false }
            }
        }.resume()
    }

    private func sendInvitations(to receiverIds: [String], reason: String) {
        for receiverId in receiverIds {
            guard let url = URL(string: "\(API.baseURL)/api/invite") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "senderId": userId,
                "receiverId": receiverId,
                "reason": reason
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error sending invitation: \(error.localizedDescription)")
                        showAlert(title: "Error", message: "Failed to send invitation: \(error.localizedDescription)")
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("Invalid response from server for invitation.")
                        showAlert(title: "Error", message: "Invalid response from server for invitation.")
                        return
                    }

                    if httpResponse.statusCode == 201 {
                        print("Invitation sent successfully to \(receiverId)")
                        showAlert(title: "Invitation Sent!", message: "Invitation sent to selected users.")
                    } else if let data = data, let message = String(data: data, encoding: .utf8) {
                        print("Failed to send invitation to \(receiverId): \(message)")
                        showAlert(title: "Error", message: "Failed to send invitation: \(message)")
                    } else {
                        print("Unknown error sending invitation to \(receiverId). Status code: \(httpResponse.statusCode)")
                        showAlert(title: "Error", message: "Unknown error sending invitation. Status code: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        }
    }

    private func updateOnlineStatus(isOnline: Bool) {
        guard let url = URL(string: "\(API.baseURL)/api/status/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "isOnline": isOnline
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating status: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                fetchNearbyUsers()
            }
        }.resume()
    }

    private func shouldSendLocationUpdate(newLocation: CLLocation) -> Bool {
        // Send if never sent, moved > 15m, or last send > 20s ago
        defer {
            lastSentLocation = newLocation
            lastSentAt = Date()
        }

        guard let lastLoc = lastSentLocation, let lastAt = lastSentAt else {
            return true
        }

        let movedMeters = newLocation.distance(from: lastLoc)
        let seconds = Date().timeIntervalSince(lastAt)
        return movedMeters > 15 || seconds > 20
    }
}

// MARK: - UserAnnotationView
struct UserAnnotationView: View {
    let user: User
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .foregroundColor(isSelected ? Color.theme.accent : Color.theme.red)
            Text(user.username)
                .font(.caption)
                .fontWeight(.light)
                .foregroundColor(.primary)
        }
        .padding(5)
        .background(Color.theme.background.opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 1)
        .onTapGesture(perform: action)
    }
}

// MARK: - SlidingPanelView
struct SlidingPanelView: View {
    @Binding var isOnline: Bool
    @Binding var radiusKm: Double
    @Binding var selectedUsers: Set<String>
    @Binding var invitationReason: String
    let onInvite: () -> Void
    let onInviteAll: () -> Void

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Map Controls")
                    .font(.title2)
                    .fontWeight(.light)
                    .foregroundColor(.primary)

                Toggle(isOn: $isOnline) {
                    Text("Online Status")
                        .font(.body)
                        .fontWeight(.light)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.theme.green))

                VStack(alignment: .leading) {
                    Text("Search Radius: \(Int(radiusKm)) km")
                        .font(.body)
                        .fontWeight(.light)
                    Slider(value: $radiusKm, in: 1...25, step: 1)
                        .tint(Color.theme.accent)
                }

                if !selectedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Send Invitation")
                            .font(.headline)
                            .fontWeight(.light)

                        TextField("Invitation Reason", text: $invitationReason)
                            .padding()
                            .background(Color.theme.accentLight)
                            .cornerRadius(10)

                        Button(action: onInvite) {
                            Text("Invite \(selectedUsers.count) User\(selectedUsers.count > 1 ? "s" : "")")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.theme.accent)
                                .cornerRadius(10)
                        }
                        .disabled(invitationReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    Button(action: onInviteAll) {
                        Text("Invite All Nearby")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.theme.accent)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(20)
            .background(Color.theme.background)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
    }
}

// MARK: - User Model
struct User: Identifiable, Decodable {
    let id: String
    let username: String
    let location: LocationData

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.coordinates[1], longitude: location.coordinates[0])
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case location
    }
}

struct LocationData: Decodable {
    let type: String
    let coordinates: [Double]
}

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
