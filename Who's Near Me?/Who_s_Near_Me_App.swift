//
//  Who_s_Near_Me_App.swift
//  Who's Near Me?
//
//  Created by Nathan Fischer on 8/1/25.
//

import SwiftUI

enum API {
    // Set this to your deployed backend URL, e.g., https://whos-near-me.fly.dev
    static let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "http://localhost:3000" // fallback for Simulator
    }()
}

@main
struct Who_s_Near_Me_App: App {
    @State private var isAuthenticated = false
    @State private var userId: String? = nil

    var body: some Scene {
        WindowGroup {
            if isAuthenticated, let userId = userId {
                ContentView(userId: userId)
            } else {
                AuthView(isAuthenticated: $isAuthenticated, userId: $userId)
            }
        }
    }
}
