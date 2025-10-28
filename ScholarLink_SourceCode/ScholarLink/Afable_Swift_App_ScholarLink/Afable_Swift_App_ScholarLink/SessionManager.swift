//
//  SessionManager.swift
//  Afable_Swift_App_ScholarLink
//
//  Created by STUDENT on 9/29/25.
//

import SwiftUI
import Foundation


struct Session: Identifiable, Codable {
    let id: UUID
    let studentId: UUID
    let tutorId: UUID
    let studentName: String
    let studentEmail: String
    let tutorName: String
    let tutorEmail: String
    let subject: String
    let sessionDate: Date
    let duration: Int
    let message: String
    let hourlyRate: Double
    var status: String
    var isCompleted: Bool
    var rating: Int?
    var review: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case tutorId = "tutor_id"
        case studentName = "student_name"
        case studentEmail = "student_email"
        case tutorName = "tutor_name"
        case tutorEmail = "tutor_email"
        case subject
        case sessionDate = "session_date"
        case duration
        case message
        case hourlyRate = "hourly_rate"
        case status
        case isCompleted = "is_completed"
        case rating
        case review
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var totalCost: Double {
        return hourlyRate * (Double(duration) / 60.0)
    }
    
    var isAccepted: Bool { status == "accepted" }
    var isPending: Bool { status == "pending" }
    var isRejected: Bool { status == "rejected" }
}


class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    
    static let shared = SessionManager()
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        Task {
            await loadSessions()
        }
    }
    
    func loadSessions() async {
        guard let currentUser = UserSession.shared.currentUser else { return }
        
        do {
            let fetchedSessions: [Session] = try await supabase
                .from("sessions")
                .select()
                .or("student_id.eq.\(currentUser.id.uuidString),tutor_id.eq.\(currentUser.id.uuidString)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.sessions = fetchedSessions
            }
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    func addSession(studentId: UUID, tutorId: UUID, studentName: String, studentEmail: String, tutorName: String, tutorEmail: String, subject: String, date: Date, duration: Int, message: String, hourlyRate: Double) async throws {
        struct NewSession: Encodable {
            let student_id: String
            let tutor_id: String
            let student_name: String
            let student_email: String
            let tutor_name: String
            let tutor_email: String
            let subject: String
            let session_date: Date
            let duration: Int
            let message: String
            let hourly_rate: Double
        }
        
        let newSession = NewSession(
            student_id: studentId.uuidString,
            tutor_id: tutorId.uuidString,
            student_name: studentName,
            student_email: studentEmail,
            tutor_name: tutorName,
            tutor_email: tutorEmail,
            subject: subject,
            session_date: date,
            duration: duration,
            message: message,
            hourly_rate: hourlyRate
        )
        
        let created: Session = try await supabase
            .from("sessions")
            .insert(newSession)
            .select()
            .single()
            .execute()
            .value
        
        await MainActor.run {
            self.sessions.insert(created, at: 0)
        }
        
        // Notify tutor
        NotificationManager.shared.notifyTutorOfNewRequest(
            tutorEmail: tutorEmail,
            studentName: studentName,
            subject: subject,
            sessionId: created.id
        )
    }
    func getSessionsForTutor(email: String) -> [Session] {
        return sessions.filter { $0.tutorEmail == email }
    }
    
    func getSessionsForStudent(email: String) -> [Session] {
        return sessions.filter { $0.studentEmail == email }
    }
    
    func acceptSession(_ session: Session) async {
        do {
            try await supabase
                .from("sessions")
                .update(["status": "accepted"])
                .eq("id", value: session.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                    self.sessions[index].status = "accepted"
                }
            }
            
            NotificationManager.shared.notifyStudentOfAcceptance(
                studentEmail: session.studentEmail,
                tutorName: session.tutorName,
                subject: session.subject,
                sessionId: session.id
            )
        } catch {
            print("Failed to accept session: \(error)")
        }
    }
    func rejectSession(_ session: Session) async {
        do {
            try await supabase
                .from("sessions")
                .update(["status": "rejected"])
                .eq("id", value: session.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                    self.sessions[index].status = "rejected"
                }
            }
            
            NotificationManager.shared.notifyStudentOfRejection(
                studentEmail: session.studentEmail,
                tutorName: session.tutorName,
                subject: session.subject,
                sessionId: session.id
            )
        } catch {
            print("Failed to reject session: \(error)")
        }
    }
    
    func getPendingSessionsForTutor(email: String) -> [Session] {
        return getSessionsForTutor(email: email).filter { $0.isPending }
    }
    
    func getAcceptedSessionsForStudent(email: String) -> [Session] {
        return getSessionsForStudent(email: email).filter { $0.isAccepted }
    }
    
    func markSessionAsComplete(_ session: Session) async {
        struct UpdateComplete: Encodable {
            let is_completed: Bool
        }
        
        do {
            try await supabase
                .from("sessions")
                .update(UpdateComplete(is_completed: true))
                .eq("id", value: session.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                    self.sessions[index].isCompleted = true
                }
            }
        } catch {
            print("Failed to mark session as complete: \(error)")
        }
    }
    
    func rateSession(_ session: Session, rating: Int, review: String) async {
        struct UpdateRating: Encodable {
            let rating: Int
            let review: String
            let is_completed: Bool
        }
        
        do {
            try await supabase
                .from("sessions")
                .update(UpdateRating(rating: rating, review: review, is_completed: true))
                .eq("id", value: session.id.uuidString)
                .execute()
            
            await MainActor.run {
                if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                    self.sessions[index].rating = rating
                    self.sessions[index].review = review
                    self.sessions[index].isCompleted = true
                }
            }
        } catch {
            print("Failed to rate session: \(error)")
        }
    }
}
