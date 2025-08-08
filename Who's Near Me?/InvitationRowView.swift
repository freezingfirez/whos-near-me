import SwiftUI

struct InvitationRowView: View {
    let invitation: Invitation
    let isReceived: Bool
    var onAction: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: isReceived ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(isReceived ? Color.theme.green : Color.theme.accent)

                VStack(alignment: .leading) {
                    Text(isReceived ? "From: \(invitation.senderUsername)" : "To: \(invitation.receiverUsername ?? "Unknown")")
                        .font(.headline)
                        .fontWeight(.medium)
                    Text(invitation.reason)
                        .font(.subheadline)
                        .foregroundColor(Color.theme.secondaryText)
                }

                Spacer()

                Text(invitation.status.capitalized)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: invitation.status))
                    .cornerRadius(8)
            }

            if isReceived && invitation.status == "pending" {
                HStack {
                    Button("Accept") {
                        onAction?("accept")
                    }
                    .buttonStyle(ActionButtonStyle(backgroundColor: Color.theme.green))

                    Button("Decline") {
                        onAction?("decline")
                    }
                    .buttonStyle(ActionButtonStyle(backgroundColor: Color.theme.red))
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.theme.background)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "pending":
            return .orange
        case "accepted":
            return Color.theme.green
        case "declined":
            return Color.theme.red
        default:
            return .gray
        }
    }
}

struct ActionButtonStyle: ButtonStyle {
    let backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
