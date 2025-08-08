import SwiftUI

struct EditProfileView: View {
    let userId: String
    @Binding var profile: Profile
    var onSave: (Profile) -> Void

    @State private var bio: String
    @State private var interests: String
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    init(userId: String, profile: Profile, onSave: @escaping (Profile) -> Void) {
        self.userId = userId
        self._profile = Binding.constant(profile)
        self.onSave = onSave
        _bio = State(initialValue: profile.bio)
        _interests = State(initialValue: profile.interests.joined(separator: ", "))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("About You")) {
                    TextField("Bio", text: $bio)
                        .frame(height: 100, alignment: .topLeading)
                        .multilineTextAlignment(.leading)
                }

                Section(header: Text("Interests (comma-separated)")) {
                    TextField("Interests", text: $interests)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(leading: Button("Cancel") {
                onSave(profile) // Pass back original profile on cancel
            }, trailing: Button("Save") {
                saveProfile()
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveProfile() {
        guard let url = URL(string: "\(API.baseURL)/api/profile/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let interestsArray = interests.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let body: [String: Any] = [
            "bio": bio,
            "interests": interestsArray
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertTitle = "Error"
                    alertMessage = "Failed to save profile: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid response from server."
                    showingAlert = true
                    return
                }

                if httpResponse.statusCode == 200 {
                    if let data = data, let decodedProfile = try? JSONDecoder().decode(Profile.self, from: data) {
                        onSave(decodedProfile)
                    } else {
                        alertTitle = "Success"
                        alertMessage = "Profile saved successfully, but could not decode updated profile."
                        showingAlert = true
                    }
                } else if let data = data, let message = String(data: data, encoding: .utf8) {
                    alertTitle = "Error"
                    alertMessage = "Failed to save profile: \(message)"
                    showingAlert = true
                } else {
                    alertTitle = "Server Error"
                    alertMessage = "Unknown error occurred. Status code: \(httpResponse.statusCode)"
                    showingAlert = true
                }
            }
        }.resume()
    }
}
