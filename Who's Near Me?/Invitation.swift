import Foundation

struct Invitation: Identifiable, Decodable {
    let id: String
    let reason: String
    let status: String

    // Unified properties for sender and receiver
    let senderId: String
    let senderUsername: String
    let receiverId: String
    let receiverUsername: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case sender
        case receiver
        case reason
        case status
    }

    // Custom decoder to handle inconsistent API responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        reason = try container.decode(String.self, forKey: .reason)
        status = try container.decode(String.self, forKey: .status)

        // Decode Sender
        if let senderObject = try? container.decode(Sender.self, forKey: .sender) {
            senderId = senderObject.id
            senderUsername = senderObject.username
        } else {
            senderId = try container.decode(String.self, forKey: .sender)
            senderUsername = "Unknown User"
        }

        // Decode Receiver
        if let receiverObject = try? container.decode(Sender.self, forKey: .receiver) {
            receiverId = receiverObject.id
            receiverUsername = receiverObject.username
        } else {
            receiverId = try container.decode(String.self, forKey: .receiver)
            receiverUsername = nil
        }
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
