import SwiftUI

struct InvitationsRootView: View {
    let userId: String
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack {
            Picker("Invitations", selection: $selectedTab) {
                Text("Received").tag(0)
                Text("Sent").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == 0 {
                InvitationsView(userId: userId)
            } else {
                SentInvitationsView(userId: userId)
            }
        }
        .navigationTitle("Invitations")
    }
}

