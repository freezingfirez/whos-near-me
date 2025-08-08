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

    init(id: String, username: String, bio: String, profilePictureUrl: String?, interests: [String], gender: String?, socialMediaLinks: [String: String]?, availabilityStatus: String?, birthday: Date?) {
        self.id = id
        self.username = username
        self.bio = bio
        self.profilePictureUrl = profilePictureUrl
        self.interests = interests
        self.gender = gender
        self.socialMediaLinks = socialMediaLinks
        self.availabilityStatus = availabilityStatus
        self.birthday = birthday
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        bio = (try? container.decode(String.self, forKey: .bio)) ?? ""
        profilePictureUrl = try? container.decode(String.self, forKey: .profilePictureUrl)
        interests = (try? container.decode([String].self, forKey: .interests)) ?? []
        gender = try? container.decode(String.self, forKey: .gender)
        socialMediaLinks = try? container.decode([String: String].self, forKey: .socialMediaLinks)
        availabilityStatus = (try? container.decode(String.self, forKey: .availabilityStatus)) ?? "Available"
        birthday = try? container.decode(Date.self, forKey: .birthday)
    }
}
