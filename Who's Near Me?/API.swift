import Foundation

enum API {
    // Set this to your deployed backend URL, e.g., https://whos-near-me.fly.dev
    static let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "http://localhost:3000" // fallback for Simulator
    }()
}