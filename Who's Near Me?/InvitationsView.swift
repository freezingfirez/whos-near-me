import SwiftUI

struct InvitationsView: View {
    let userId: String
    @State private var receivedInvitations: [Invitation] = []
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List {
                if receivedInvitations.isEmpty {
                    Text("No invitations received.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(receivedInvitations) { invitation in
                        VStack(alignment: .leading) {
                            Text("From: \(invitation.sender.username)")
                                .font(.headline)
                            Text("Reason: \(invitation.reason)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                Button("Accept") {
                                    handleInvitation(invitationId: invitation.id, action: "accept")
                                }
                                .padding(.horizontal)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(5)

                                Button("Decline") {
                                    handleInvitation(invitationId: invitation.id, action: "decline")
                                }
                                .padding(.horizontal)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("My Invitations")
            .onAppear(perform: fetchReceivedInvitations)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchReceivedInvitations() {
        guard let url = URL(string: "\(API.baseURL)/api/invitations/received/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching received invitations: \(error.localizedDescription)")
                    showAlert(title: "Error", message: "Failed to fetch invitations: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data received for invitations.")
                    return
                }

                do {
                    let decodedInvitations = try JSONDecoder().decode([Invitation].self, from: data)
                    self.receivedInvitations = decodedInvitations.filter { $0.status == "pending" }
                } catch {
                    print("Error decoding invitations: \(error.localizedDescription)")
                    showAlert(title: "Error", message: "Failed to decode invitations: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func handleInvitation(invitationId: String, action: String) {
        guard let url = URL(string: "\(API.baseURL)/api/invite/\(invitationId)/\(action)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error handling invitation: \(error.localizedDescription)")
                    showAlert(title: "Error", message: "Failed to \(action) invitation: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response from server for invitation action.")
                    showAlert(title: "Error", message: "Invalid response from server for invitation action.")
                    return
                }

                if httpResponse.statusCode == 200 {
                    showAlert(title: "Success", message: "Invitation \(action)ed successfully.")
                    fetchReceivedInvitations() // Refresh the list
                } else if let data = data, let message = String(data: data, encoding: .utf8) {
                    showAlert(title: "Error", message: "Failed to \(action) invitation: \(message)")
                } else {
                    showAlert(title: "Error", message: "Unknown error \(action)ing invitation. Status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct Invitation: Identifiable, Decodable {
    let id: String
    let sender: Sender
    let reason: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case sender
        case reason
        case status
    }
}

struct Sender: Decodable {
    let id: String
    let username: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
    }
}

struct InvitationsView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationsView(userId: "60c72b2f9b1e8b001c8e4d7a") // Example userId
    }
}
