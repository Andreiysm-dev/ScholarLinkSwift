import Foundation
import UserNotifications

struct SessionReminder: Identifiable {
    enum LeadTime: TimeInterval, CaseIterable {
        case oneDay = 86_400
        case oneHour = 3_600
        
        var description: String {
            switch self {
            case .oneDay: return "24 hours"
            case .oneHour: return "1 hour"
            }
        }
    }
    
    let id: String
    let sessionId: UUID
    let subject: String
    let tutorName: String
    let fireDate: Date
    let leadTimeDescription: String
    
    var relativeDescription: String {
        fireDate.formatted(date: .abbreviated, time: .shortened)
    }
}

@MainActor
final class SessionReminderScheduler: ObservableObject {
    static let shared = SessionReminderScheduler()
    
    @Published private(set) var upcomingReminders: [SessionReminder] = []
    
    private let center = UNUserNotificationCenter.current()
    private let scheduledKey = "scheduled_session_reminders"
    private var scheduledIDs: Set<String> {
        get {
            let stored = UserDefaults.standard.array(forKey: scheduledKey) as? [String] ?? []
            return Set(stored)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: scheduledKey)
        }
    }
    
    private init() {}
    
    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    print("Notification authorization error: \(error)")
                } else if !granted {
                    print("Notification authorization denied by user")
                }
            }
        }
    }
    
    func syncReminders(with sessions: [Session]) {
        let now = Date()
        var desiredIDs = Set<String>()
        var reminders: [SessionReminder] = []
        
        let relevantSessions = sessions.filter { $0.isAccepted && !$0.isCompleted && $0.sessionDate > now }
        
        for session in relevantSessions {
            for lead in SessionReminder.LeadTime.allCases {
                let fireDate = session.sessionDate.addingTimeInterval(-lead.rawValue)
                guard fireDate > now else { continue }
                
                let reminderID = identifier(for: session.id, lead: lead)
                desiredIDs.insert(reminderID)
                
                if !scheduledIDs.contains(reminderID) {
                    scheduleNotification(
                        id: reminderID,
                        session: session,
                        fireDate: fireDate,
                        lead: lead
                    )
                }
                
                reminders.append(
                    SessionReminder(
                        id: reminderID,
                        sessionId: session.id,
                        subject: session.subject,
                        tutorName: session.tutorName,
                        fireDate: fireDate,
                        leadTimeDescription: lead.description
                    )
                )
            }
        }
        
        let staleIDs = scheduledIDs.subtracting(desiredIDs)
        if !staleIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(staleIDs))
        }
        
        scheduledIDs = desiredIDs
        upcomingReminders = reminders.sorted { $0.fireDate < $1.fireDate }
    }
    
    private func scheduleNotification(
        id: String,
        session: Session,
        fireDate: Date,
        lead: SessionReminder.LeadTime
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming \(session.subject) session"
        content.body = "\(session.tutorName) meets you in \(lead.description.lowercased())."
        content.sound = .default
        
        let interval = max(fireDate.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule reminder \(id): \(error)")
            }
        }
    }
    
    private func identifier(for sessionId: UUID, lead: SessionReminder.LeadTime) -> String {
        "\(sessionId.uuidString)-\(Int(lead.rawValue))"
    }
}

