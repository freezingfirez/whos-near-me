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
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(Color.theme.accent)

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
                EditProfileView(userId: userId, profile: profile ?? Profile(id: userId, username: "", bio: "", profilePictureUrl: "", interests: []), onSave: { updatedProfile in
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

                do {
                    let decodedProfile = try JSONDecoder().decode(Profile.self, from: data)
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


