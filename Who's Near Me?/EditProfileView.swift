import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let userId: String
    @Binding var profile: Profile
    var onSave: (Profile) -> Void

    @State private var bio: String
    @State private var interests: String
    @State private var profilePictureData: Data? // For selected image
    @State private var gender: String
    @State private var twitterLink: String
    @State private var linkedinLink: String
    @State private var availabilityStatus: String
    @State private var birthday: Date

    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    let genderOptions = ["", "Male", "Female", "Non-binary", "Prefer not to say"]
    let availabilityOptions = ["Available", "Busy", "Offline"]

    init(userId: String, profile: Profile, onSave: @escaping (Profile) -> Void) {
        self.userId = userId
        self._profile = Binding.constant(profile)
        self.onSave = onSave
        _bio = State(initialValue: profile.bio)
        _interests = State(initialValue: profile.interests.joined(separator: ", "))
        _gender = State(initialValue: profile.gender)
        _twitterLink = State(initialValue: profile.socialMediaLinks["twitter"] ?? "")
        _linkedinLink = State(initialValue: profile.socialMediaLinks["linkedin"] ?? "")
        _availabilityStatus = State(initialValue: profile.availabilityStatus)
        _birthday = State(initialValue: profile.birthday ?? Date())

        if let data = Data(base64Encoded: profile.profilePictureUrl) {
            _profilePictureData = State(initialValue: data)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let profilePictureData = profilePictureData, let uiImage = UIImage(data: profilePictureData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.theme.accent, lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                        Spacer()
                    }
                }

                Section(header: Text("About You")) {
                    TextField("Bio", text: $bio)
                        .frame(height: 100, alignment: .topLeading)
                        .multilineTextAlignment(.leading)

                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) {
                            Text($0)
                        }
                    }

                    DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                }

                Section(header: Text("Interests (comma-separated)")) {
                    TextField("Interests", text: $interests)
                }

                Section(header: Text("Social Media")) {
                    TextField("Twitter", text: $twitterLink)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("LinkedIn", text: $linkedinLink)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Availability")) {
                    Picker("Status", selection: $availabilityStatus) {
                        ForEach(availabilityOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(leading: Button("Cancel") {
                onSave(profile) // Pass back original profile on cancel
            }, trailing: Button("Save") {
                saveProfile()
            })
            .sheet(isPresented: $showingImagePicker) {
                PhotoPicker(profilePictureData: $profilePictureData)
            }
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
        var socialMediaLinks: [String: String] = [:]
        if !twitterLink.isEmpty { socialMediaLinks["twitter"] = twitterLink }
        if !linkedinLink.isEmpty { socialMediaLinks["linkedin"] = linkedinLink }

        let profilePictureBase64 = profilePictureData?.base64EncodedString()

        let body: [String: Any] = [
            "bio": bio,
            "interests": interestsArray,
            "profilePictureUrl": profilePictureBase64 ?? "",
            "gender": gender,
            "socialMediaLinks": socialMediaLinks,
            "availabilityStatus": availabilityStatus,
            "birthday": ISO8601DateFormatter().string(from: birthday)
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

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                if httpResponse.statusCode == 200 {
                    if let data = data, let response = try? decoder.decode(ProfileUpdateResponse.self, from: data) {
                        onSave(response.user)
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
