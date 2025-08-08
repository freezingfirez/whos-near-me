import SwiftUI

struct AuthView: View {
    @State private var isRegistering = false
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Binding var isAuthenticated: Bool
    @Binding var userId: String?

    var body: some View {
        ZStack {
            Color.theme.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 25) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 100))
                    .foregroundColor(Color.theme.accent)
                    .padding(.bottom, 20)

                Text("Who's Near Me?")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundColor(.primary)

                Text(isRegistering ? "Create Your Account" : "Welcome Back")
                    .font(.title2)
                    .fontWeight(.light)
                    .foregroundColor(Color.theme.secondaryText)

                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.theme.accentLight)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.theme.accentLight)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: {
                        if isRegistering {
                            registerUser()
                        } else {
                            loginUser()
                        }
                    }) {
                        Text(isRegistering ? "Register" : "Login")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.theme.accent)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    isRegistering.toggle()
                }) {
                    Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                        .font(.callout)
                        .foregroundColor(Color.theme.accent)
                }
            }
            .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func registerUser() {
        isLoading = true
        guard let url = URL(string: "\(API.baseURL)/api/register") else { return }
        let body: [String: Any] = ["username": username, "password": password, "latitude": 0.0, "longitude": 0.0] // Placeholder location

        performAuthRequest(url: url, body: body) {
            alertTitle = "Registration Success"
            alertMessage = "You have successfully registered! Please log in."
            showingAlert = true
            isRegistering = false // Switch to login after successful registration
        }
    }

    private func loginUser() {
        isLoading = true
        guard let url = URL(string: "\(API.baseURL)/api/login") else { return }
        let body: [String: Any] = ["username": username, "password": password]

        performAuthRequest(url: url, body: body) {
            alertTitle = "Login Success"
            alertMessage = "You have successfully logged in!"
            showingAlert = true
            isAuthenticated = true // Set isAuthenticated to true on successful login
        }
    }

    private func performAuthRequest(url: URL, body: [String: Any], onSuccess: @escaping () -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    alertTitle = "Network Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid response from server."
                    showingAlert = true
                    return
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let receivedUserId = json["userId"] as? String {
                        self.userId = receivedUserId
                        KeychainHelper.saveUserId(receivedUserId)
                    }
                    onSuccess()
                } else if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: String], let message = json["msg"] {
                    alertTitle = "Error"
                    alertMessage = message
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

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(isAuthenticated: .constant(false), userId: .constant(nil))
    }
}
