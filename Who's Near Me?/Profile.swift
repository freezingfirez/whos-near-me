import Foundation

struct Profile: Identifiable, Codable {
    let id: String
    let username: String
    var bio: String
    var profilePictureUrl: String?
    var interests: [String]
    var gender: String?
    var socialMediaLinks: [String: String]?
    var availabilityStatus: String?
    var birthday: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case bio
        case profilePictureUrl
        case interests
        case gender
        case socialMediaLinks
        case availabilityStatus
        case birthday
    }
}
