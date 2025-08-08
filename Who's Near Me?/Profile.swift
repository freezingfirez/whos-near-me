import Foundation

struct Profile: Identifiable, Codable {
    let id: String
    let username: String
    var bio: String
    var profilePictureUrl: String
    var interests: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case bio
        case profilePictureUrl
        case interests
    }
}
