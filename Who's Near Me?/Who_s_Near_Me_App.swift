import SwiftUI

@main
struct Who_s_Near_Me_App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isAuthenticated = false
    @State private var userId: String? = nil

    init() {
        if let userId = KeychainHelper.getUserId() {
            _isAuthenticated = State(initialValue: true)
            _userId = State(initialValue: userId)
        } else {
            _isAuthenticated = State(initialValue: false)
            _userId = State(initialValue: nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            if isAuthenticated, let userId = userId {
                MainTabView(userId: userId, isAuthenticated: $isAuthenticated)
            } else {
                AuthView(isAuthenticated: $isAuthenticated, userId: $userId)
            }
        }
    }
}
