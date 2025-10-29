import SwiftUI
import Foundation

// Notification structure
struct AppNotification: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let message: String
    let type: String
    let relatedId: UUID?
    var isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case message
        case type
        case relatedId = "related_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    var icon: String {
        switch type {
        case "session_request": return "calendar.badge.plus"
        case "session_accepted": return "checkmark.circle.fill"
        case "session_rejected": return "xmark.circle.fill"
        default: return "bell.fill"
        }
    }
    
    var color: Color {
        switch type {
        case "session_request": return .blue
        case "session_accepted": return .green
        case "session_rejected": return .red
        default: return .gray
        }
    }
}

// Notification manager
class NotificationManager: ObservableObject {
    @Published var notifications: [AppNotification] = []
    
    static let shared = NotificationManager()
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        Task {
            await loadNotifications()
        }
    }
    
    func loadNotifications() async {
        guard let currentUser = UserSession.shared.currentUser else { return }
        
        do {
            let fetchedNotifications: [AppNotification] = try await supabase
                .from("notifications")
                .select()
                .eq("user_id", value: currentUser.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.notifications = fetchedNotifications
            }
        } catch {
            print("Failed to load notifications: \(error)")
        }
    }
    
    func addNotification(userId: UUID, title: String, message: String, type: String, relatedId: UUID?) async {
        struct NotificationParams: Encodable {
            let p_user_id: String
            let p_title: String
            let p_message: String
            let p_type: String
            let p_related_id: String?
        }
        
        let params = NotificationParams(
            p_user_id: userId.uuidString,
            p_title: title,
            p_message: message,
            p_type: type,
            p_related_id: relatedId?.uuidString
        )
        
        do {
            // Use RPC to create notification (bypasses RLS)
            let _: String = try await supabase
                .rpc("create_notification", params: params)
                .single()
                .execute()
                .value
            
            // Reload notifications if this is for the current user
            if let currentUser = UserSession.shared.currentUser, currentUser.id == userId {
                await loadNotifications()
            }
        } catch {
            print("Failed to add notification: \(error)")
        }
    }
    
    func getNotificationsForUser(userId: UUID) -> [AppNotification] {
        return notifications.filter { $0.userId == userId }
    }
    
    func getUnreadNotificationsForUser(userId: UUID) -> [AppNotification] {
        return getNotificationsForUser(userId: userId).filter { !$0.isRead }
    }
    
    func markAsRead(_ notification: AppNotification) async {
        do {
            try await supabase
                .from("notifications")
                .update(["is_read": true])
                .eq("id", value: notification.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                    self.notifications[index].isRead = true
                }
            }
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }
    
    func markAllAsReadForUser(userId: UUID) async {
        do {
            try await supabase
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: userId.uuidString)
                .eq("is_read", value: false)
                .execute()
            
            await MainActor.run {
                for i in self.notifications.indices {
                    if self.notifications[i].userId == userId {
                        self.notifications[i].isRead = true
                    }
                }
            }
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
    
    // Convenience methods for common notifications
    func notifyTutorOfNewRequest(tutorEmail: String, studentName: String, subject: String, sessionId: UUID) {
        Task {
            do {
                let tutor: User = try await supabase
                    .from("profiles")
                    .select()
                    .eq("email", value: tutorEmail)
                    .single()
                    .execute()
                    .value
                
                await addNotification(
                    userId: tutor.id,
                    title: "New Session Request",
                    message: "\(studentName) wants to book a \(subject) session with you",
                    type: "session_request",
                    relatedId: sessionId
                )
            } catch {
                print("Failed to notify tutor: \(error)")
            }
        }
    }
    
    func notifyStudentOfAcceptance(studentEmail: String, tutorName: String, subject: String, sessionId: UUID) {
        Task {
            do {
                let student: User = try await supabase
                    .from("profiles")
                    .select()
                    .eq("email", value: studentEmail)
                    .single()
                    .execute()
                    .value
                
                await addNotification(
                    userId: student.id,
                    title: "Session Accepted! 🎉",
                    message: "\(tutorName) accepted your \(subject) session request",
                    type: "session_accepted",
                    relatedId: sessionId
                )
            } catch {
                print("Failed to notify student: \(error)")
            }
        }
    }
    
    func notifyStudentOfRejection(studentEmail: String, tutorName: String, subject: String, sessionId: UUID) {
        Task {
            do {
                let student: User = try await supabase
                    .from("profiles")
                    .select()
                    .eq("email", value: studentEmail)
                    .single()
                    .execute()
                    .value
                
                await addNotification(
                    userId: student.id,
                    title: "Session Request Declined",
                    message: "\(tutorName) declined your \(subject) session request",
                    type: "session_rejected",
                    relatedId: sessionId
                )
            } catch {
                print("Failed to notify student: \(error)")
            }
        }
    }
    
    func getUnreadCount(for userId: UUID) -> Int {
        return getUnreadNotificationsForUser(userId: userId).count
    }
}
