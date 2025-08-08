import SwiftUI

struct SentInvitationsView: View {
    let userId: String
    @State private var sentInvitations: [Invitation] = []
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        List {
            if sentInvitations.isEmpty {
                Text("No invitations sent.")
                    .foregroundColor(.gray)
            } else {
                ForEach(sentInvitations) { invitation in
                    InvitationRowView(invitation: invitation, isReceived: false)
                }
            }
        }
        .navigationTitle("Sent Invitations")
        .onAppear(perform: fetchSentInvitations)
        .refreshable {
            fetchSentInvitations()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func fetchSentInvitations() {
        guard let url = URL(string: "\(API.baseURL)/api/invitations/sent/\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertTitle = "Error"
                    alertMessage = "Failed to fetch invitations: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }

                guard let data = data else { return }

                do {
                    let decodedInvitations = try JSONDecoder().decode([Invitation].self, from: data)
                    self.sentInvitations = decodedInvitations
                } catch {
                    alertTitle = "Error"
                    alertMessage = "Failed to decode invitations: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }.resume()
    }
}


