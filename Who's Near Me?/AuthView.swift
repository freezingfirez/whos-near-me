import SwiftUI

struct AuthView: View {
    @State private var isRegistering = false
    @State private var username = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Binding var isAuthenticated: Bool
    @Binding var userId: String?

    var body: some View {
        VStack {
            Text(isRegistering ? "Register" : "Login")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                if isRegistering {
                    registerUser()
                } else {
                    loginUser()
                }
            }) {
                Text(isRegistering ? "Register" : "Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()

            Button(action: {
                isRegistering.toggle()
            }) {
                Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func registerUser() {
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
                if let error = error {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertTitle = "Error"
                    alertMessage = "Invalid response from server."
                    showingAlert = true
                    return
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let receivedUserId = json["userId"] as? String {
                        self.userId = receivedUserId
                    }
                    onSuccess()
                } else if let data = data, let message = String(data: data, encoding: .utf8) {
                    alertTitle = "Error"
                    alertMessage = message
                    showingAlert = true
                } else {
                    alertTitle = "Error"
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
