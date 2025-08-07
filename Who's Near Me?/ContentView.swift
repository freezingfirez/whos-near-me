//
//  ContentView.swift
//  Who's Near Me?
//
//  Created by Nathan Fischer on 8/1/25.
//

import SwiftUI
import MapKit
import CoreLocation

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

    var body: some View {
        VStack {
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                Map(coordinateRegion: .constant(MKCoordinateRegion(center: locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))), showsUserLocation: true, annotationItems: nearbyUsers) { user in
                    MapAnnotation(coordinate: user.coordinate) {
                        VStack {
                            Image(systemName: selectedUsers.contains(user.id) ? "person.fill.checkmark" : "person.fill")
                                .foregroundColor(selectedUsers.contains(user.id) ? .blue : .red)
                                .font(.title)
                            Text(user.username)
                                .font(.caption)
                        }
                        .onTapGesture {
                            if selectedUsers.contains(user.id) {
                                selectedUsers.remove(user.id)
                            } else {
                                selectedUsers.insert(user.id)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)

                HStack {
                    Toggle(isOn: $isOnline) {
                        Text("Online Status")
                    }
                    .padding()

                    Spacer()

                    TextField("Invitation Reason", text: $invitationReason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    if !selectedUsers.isEmpty {
                        Button("Invite Selected") {
                            sendInvitations(to: Array(selectedUsers), reason: invitationReason)
                            selectedUsers.removeAll()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button("Invite All") {
                        sendInvitations(to: nearbyUsers.map { $0.id }, reason: invitationReason)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("My Invitations") {
                        showingInvitationsSheet = true
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingInvitationsSheet) {
                    InvitationsView(userId: userId)
                }

            } else {
                Text("Please enable location services in Settings to use this app.")
                    .padding()
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Initial fetch of nearby users
            fetchNearbyUsers()
            updateOnlineStatus(isOnline: isOnline)
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if isOnline, let location = newLocation {
                updateUserLocation(location: location)
            }
        }
        .onChange(of: isOnline) { newValue in
            updateOnlineStatus(isOnline: newValue)
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
            fetchNearbyUsers() // Fetch nearby users after updating location
        }.resume()
    }

    private func fetchNearbyUsers() {
        guard let url = URL(string: "\(API.baseURL)/api/nearby/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching nearby users: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received for nearby users.")
                return
            }

            do {
                let decodedUsers = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self.nearbyUsers = decodedUsers
                }
            } catch {
                print("Error decoding nearby users: \(error.localizedDescription)")
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
            fetchNearbyUsers()
        }.resume()
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

// Remove invalid Preview to avoid build issues since ContentView needs a userId
