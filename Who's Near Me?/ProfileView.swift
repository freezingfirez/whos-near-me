import SwiftUI

struct ProfileView: View {
    let userId: String
    @Binding var isAuthenticated: Bool
    @State private var profile: Profile? = nil
    @State private var showingEditProfileSheet = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.edgesIgnoringSafeArea(.all)

                VStack(spacing: 25) {
                    if let profile = profile {
                        if let profilePictureUrl = profile.profilePictureUrl, let imageData = Data(base64Encoded: profilePictureUrl), let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.theme.accent, lineWidth: 4))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(Color.theme.accent)
                        }

                        Text(profile.username)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(profile.bio)
                            .font(.body)
                            .foregroundColor(Color.theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Interests:")
                                .font(.headline)
                                .fontWeight(.medium)
                            ForEach(profile.interests, id: \.self) {
                                Text($0)
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.theme.accentLight)
                                    .cornerRadius(5)
                            }
                        }

                        if let gender = profile.gender, !gender.isEmpty {
                            Text("Gender: \(gender)")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.secondaryText)
                        }

                        if let birthday = profile.birthday {
                            Text("Birthday: \(birthday, formatter: DateFormatter.shortDate)")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.secondaryText)
                        }

                        if let socialMediaLinks = profile.socialMediaLinks, !socialMediaLinks.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Social Media:")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                ForEach(socialMediaLinks.sorted(by: <), id: \.key) { key, value in
                                    Text("\(key.capitalized): \(value)")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.secondaryText)
                                }
                            }
                        }

                        if let availabilityStatus = profile.availabilityStatus, !availabilityStatus.isEmpty {
                            Text("Status: \(availabilityStatus)")
                                .font(.subheadline)
                                .foregroundColor(Color.theme.secondaryText)
                        }

                        Button(action: {
                            showingEditProfileSheet = true
                        }) {
                            Text("Edit Profile")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.theme.accent)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)

                    } else {
                        ProgressView()
                    }

                    Spacer()

                    Button(action: {
                        KeychainHelper.deleteUserId()
                        isAuthenticated = false
                    }) {
                        Text("Logout")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.theme.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 30)
            }
            .navigationTitle("Profile")
            .onAppear(perform: fetchProfile)
            .sheet(isPresented: $showingEditProfileSheet) {
                EditProfileView(userId: userId, profile: profile ?? Profile(id: userId, username: "", bio: "", interests: [], gender: nil, socialMediaLinks: nil, availabilityStatus: nil, birthday: nil), onSave: { updatedProfile in
                    self.profile = updatedProfile
                    showingEditProfileSheet = false
                })
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchProfile() {
        guard let url = URL(string: "\(API.baseURL)/api/profile/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertTitle = "Error"
                    alertMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }

                guard let data = data else {
                    print("No data received for profile.")
                    return
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                do {
                    let decodedProfile = try decoder.decode(Profile.self, from: data)
                    self.profile = decodedProfile
                } catch {
                    alertTitle = "Error"
                    alertMessage = "Failed to decode profile: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }.resume()
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}


