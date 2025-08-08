import SwiftUI

struct MainTabView: View {
    let userId: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        TabView {
            ContentView(userId: userId)
                .tabItem {
                    Image(systemName: "map")
                    Text("Nearby")
                }

            InvitationsRootView(userId: userId)
                .tabItem {
                    Image(systemName: "envelope")
                    Text("Invites")
                }

            ProfileView(userId: userId, isAuthenticated: $isAuthenticated)
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

