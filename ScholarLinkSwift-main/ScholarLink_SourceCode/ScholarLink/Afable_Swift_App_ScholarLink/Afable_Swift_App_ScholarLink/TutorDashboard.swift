//
//  TutorDashboard.swift
//  Afable_Swift_App_ScholarLink
//
//  Created by STUDENT on 9/29/25.
//

import SwiftUI

struct TutorDashboardView: View {
    @StateObject private var sessionManager = SessionManager.shared
    
    var currentTutor: User? {
        return UserSession.shared.currentUser
    }
    
    var tutorSessions: [Session] {
        guard let tutor = currentTutor else { return [] }
        return sessionManager.getSessionsForTutor(email: tutor.email)
    }
    
    var pendingRequests: [Session] {
        tutorSessions.filter { $0.isPending }
    }
    
    var acceptedSessions: [Session] {
        tutorSessions.filter { $0.isAccepted }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // WELCOME
                    VStack(spacing: 12) {
                        Text("Tutor Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let tutor = currentTutor {
                            Text("Welcome, \(tutor.firstName)!")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        // STATS DASHBOARD
                        HStack(spacing: 20) {
                            StatCard(title: "Pending", count: pendingRequests.count, color: .orange, icon: "checkmark.circle.fill")
                            StatCard(title: "Accepted", count: acceptedSessions.count, color: .green, icon: "clock.fill")
                            StatCard(title: "Total Requests", count: tutorSessions.count, color: .blue, icon: "calendar")
                        }
                    }
                    .padding()
                    
                    // PENDING REQUESTS
                    if !pendingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pending Requests")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ForEach(pendingRequests) { request in
                                SessionRequestCard(
                                    session: request,
                                    onAccept: { acceptSession(request) },
                                    onReject: { rejectSession(request) }
                                )
                            }
                        }
                    }
                    
                    // UPCOMING SESSIONS
                    if !acceptedSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upcoming Sessions")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ForEach(acceptedSessions) { session in
                                AcceptedSessionCard(session: session)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await sessionManager.loadSessions()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await sessionManager.loadSessions()
            }
        }
    }
    
    private func acceptSession(_ session: Session) {
        Task {
            await sessionManager.acceptSession(session)
        }
    }
    
    private func rejectSession(_ session: Session) {
        Task {
            await sessionManager.rejectSession(session)
        }
    }
}

struct SessionRequestCard: View {
    let session: Session
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(session.studentName.prefix(2)))
                            .font(.headline)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.studentName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(session.studentEmail)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("PHP\(Int(session.totalCost))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(session.subject, systemImage: "book.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Label("\(session.duration) min", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Label(session.sessionDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if !session.message.isEmpty {
                    Text("Message: \(session.message)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct AcceptedSessionCard: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(session.studentName.prefix(2)))
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.studentName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(session.subject)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.sessionDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(session.duration) min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct TutorDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        TutorDashboardView()
    }
}
