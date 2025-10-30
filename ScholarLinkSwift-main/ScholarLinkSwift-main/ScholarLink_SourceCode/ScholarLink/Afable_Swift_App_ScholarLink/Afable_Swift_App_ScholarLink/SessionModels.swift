import Foundation
import SwiftUI

struct SessionRequest: Codable, Identifiable {
    let id: UUID
    var studentId: String
    var tutorId: String
    var subject: String
    var requestedDate: Date
    var duration: Int
    var message: String
    var status: String
    var dateCreated: Date
    var hourlyRate: Double

    var isAccepted: Bool { status == "accepted" }
    var isPending: Bool { status == "pending" }
    var isRejected: Bool { status == "rejected" }
    
    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case tutorId = "tutor_id"
        case subject
        case requestedDate = "requested_date"
        case duration
        case message
        case status
        case dateCreated = "date_created"
        case hourlyRate = "hourly_rate"
    }
}

enum SessionStatus: String, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .red
        }
    }
}


extension Date {
    var sessionDateFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
