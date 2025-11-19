import SwiftUI

struct TutorVerificationBadge: View {
    let status: TutorVerificationStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption)
            Text(status.label)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(20)
    }
    
    private var iconName: String {
        switch status {
        case .notSubmitted:
            return "shield.slash"
        case .pendingReview:
            return "hourglass"
        case .verified:
            return "checkmark.seal.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .notSubmitted:
            return Color.gray.opacity(0.15)
        case .pendingReview:
            return Color.orange.opacity(0.15)
        case .verified:
            return Color.green.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .notSubmitted:
            return .gray
        case .pendingReview:
            return .orange
        case .verified:
            return .green
        }
    }
}

struct TutorVerificationDetailCard: View {
    let status: TutorVerificationStatus
    let idType: String?
    let credentialLink: String?
    let referenceContact: String?
    let idImageLink: String?
    var showSensitiveLinks: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Verification")
                    .font(.headline)
                Spacer()
                TutorVerificationBadge(status: status)
            }
            
            Text(status.helperText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            if let idType, !idType.isEmpty {
                Label("ID Submitted: \(idType)", systemImage: "idcard")
                    .font(.subheadline)
            }
            
            if let referenceContact, !referenceContact.isEmpty {
                Label("Reference: \(referenceContact)", systemImage: "person.2")
                    .font(.subheadline)
            }
            
            if showSensitiveLinks, let credentialURL {
                Link(destination: credentialURL) {
                    Label("View credentials", systemImage: "doc.richtext")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else if credentialLink != nil {
                Label("Credentials on file", systemImage: "doc.richtext")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if showSensitiveLinks, let idURL = idImageURL {
                Link(destination: idURL) {
                    Label("View ID image", systemImage: "photo")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    private var credentialURL: URL? {
        guard let credentialLink, !credentialLink.isEmpty else { return nil }
        if credentialLink.lowercased().hasPrefix("http") {
            return URL(string: credentialLink)
        }
        return URL(string: "https://\(credentialLink)")
    }
    
    private var idImageURL: URL? {
        guard let idImageLink, !idImageLink.isEmpty else { return nil }
        if idImageLink.lowercased().hasPrefix("http") {
            return URL(string: idImageLink)
        }
        return URL(string: "https://\(idImageLink)")
    }
}

