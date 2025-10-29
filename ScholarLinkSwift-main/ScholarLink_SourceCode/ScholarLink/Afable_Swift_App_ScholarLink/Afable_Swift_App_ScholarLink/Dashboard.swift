import SwiftUI

struct DashboardView: View {
    @State private var selectedTab = 0
    
    @ObservedObject private var sessionManager = SessionManager.shared
    
    var currentUser: User? {
        return UserSession.shared.currentUser
    }
    
    var acceptedSessions: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getAcceptedSessionsForStudent(email: user.email)
    }
    
    var allStudentSessions: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForStudent(email: user.email)
    }
    
    var pendingSessions: [Session] {
        allStudentSessions.filter { $0.isPending }
    }
    
    var rejectedSessions: [Session] {
        allStudentSessions.filter { $0.isRejected }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            tabSelection
            
            Group {
                switch selectedTab {
                case 0:
                    dashboardTabContent
                case 1:
                    tutorsTabContent
                case 2:
                    activityTabContent
                default:
                    dashboardTabContent
                }
            }
            .refreshable {
                await sessionManager.loadSessions()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            Task {
                await sessionManager.loadSessions()
            }
        }
    }
    
    var dashboardTabContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                sessionStatsSection
                tutorCardsSection
                recentActivitySection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    var tutorsTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("My Tutors")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                if acceptedSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No tutors yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Book a session to see your tutors here")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    let tutorGroups = Dictionary(grouping: acceptedSessions, by: { $0.tutorEmail })
                    
                    ForEach(Array(tutorGroups.keys), id: \.self) { tutorEmail in
                        if let sessions = tutorGroups[tutorEmail] {
                            TutorDetailCard(tutorEmail: tutorEmail, sessions: sessions)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
    }
    
    var activityTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Session Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                if allStudentSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No activity yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Your session history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        if !acceptedSessions.isEmpty {
                            Text("Confirmed (\(acceptedSessions.count))")
                                .font(.headline)
                                .foregroundColor(.green)
                                .padding(.horizontal, 20)
                            
                            ForEach(acceptedSessions) { session in
                                ActivitySessionCard(session: session, statusColor: .green)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        if !pendingSessions.isEmpty {
                            Text("Pending (\(pendingSessions.count))")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            ForEach(pendingSessions) { session in
                                ActivitySessionCard(session: session, statusColor: .orange)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        if !rejectedSessions.isEmpty {
                            Text("Rejected (\(rejectedSessions.count))")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            ForEach(rejectedSessions) { session in
                                ActivitySessionCard(session: session, statusColor: .red)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
    }
    
    var tabSelection: some View {
        HStack(spacing: 40) {
            TabButton(title: "Dashboard", isSelected: selectedTab == 0) { selectedTab = 0 }
            TabButton(title: "Tutors", isSelected: selectedTab == 1) { selectedTab = 1 }
            TabButton(title: "Activity", isSelected: selectedTab == 2) { selectedTab = 2 }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    var sessionStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Session Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let user = currentUser {
                    Text("Welcome, \(user.firstName)!")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatCard(title: "Confirmed", count: acceptedSessions.count, color: .green, icon: "checkmark.circle.fill")
                StatCard(title: "Pending", count: pendingSessions.count, color: .orange, icon: "clock.fill")
                StatCard(title: "Total", count: allStudentSessions.count, color: .blue, icon: "calendar")
            }
        }
    }
    
    var tutorCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Tutors")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !acceptedSessions.isEmpty {
                    Text("\(Set(acceptedSessions.map { $0.tutorEmail }).count) Tutors")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            if acceptedSessions.isEmpty {
                EmptySessionCard()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(Array(Set(acceptedSessions.map { $0.tutorEmail })), id: \.self) { tutorEmail in
                        MyTutorCard(tutorEmail: tutorEmail, sessions: acceptedSessions.filter { $0.tutorEmail == tutorEmail })
                    }
                }
            }
        }
    }
    
    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Sessions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !acceptedSessions.isEmpty {
                    Text("\(acceptedSessions.count) Booked")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            if acceptedSessions.isEmpty {
                EmptySessionCard()
            } else {
                ForEach(acceptedSessions.prefix(3), id: \.id) { session in
                    SessionActivityRow(session: session)
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .blue : .gray)
                .padding(.bottom, 8)
                .overlay(Rectangle().frame(height: 2).foregroundColor(isSelected ? .blue : .clear), alignment: .bottom)
        }
    }
}

struct ActivityRow: View {
    let activity: String
    let detail: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Spacer()
            Text(detail)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SessionActivityRow: View {
    let session: Session
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.subject) with \(session.tutorName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(session.sessionDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.duration) min")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                Text("$\(Int(session.totalCost))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                Text("Confirmed")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct MyTutorCard: View {
    let tutorEmail: String
    let sessions: [Session]
    
    var tutorName: String { sessions.first?.tutorName ?? "Tutor" }
    var totalSessions: Int { sessions.count }
    var nextSession: Session? {
        sessions.filter { $0.sessionDate > Date() }
            .sorted { $0.sessionDate < $1.sessionDate }
            .first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Text(String(tutorName.prefix(2))).font(.subheadline).foregroundColor(.blue).fontWeight(.bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tutorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text("\(totalSessions) session\(totalSessions == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            if let next = nextSession {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Session")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    Text(next.subject)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(next.sessionDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                Text("All sessions completed")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EmptySessionCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Sessions Yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("Book a session with a tutor to get started!")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct TutorDetailCard: View {
    let tutorEmail: String
    let sessions: [Session]
    
    var tutorName: String { sessions.first?.tutorName ?? "Tutor" }
    var totalSessions: Int { sessions.count }
    var upcomingSessions: [Session] {
        sessions.filter { $0.sessionDate > Date() }.sorted { $0.sessionDate < $1.sessionDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(tutorName.prefix(2)))
                            .font(.headline)
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tutorName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("\(totalSessions) session\(totalSessions == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let rate = sessions.first?.hourlyRate {
                    Text("$\(Int(rate))/hr")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            if !upcomingSessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Session")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.semibold)
                    
                    if let next = upcomingSessions.first {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(next.subject)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(next.sessionDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(next.duration) min")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ActivitySessionCard: View {
    let session: Session
    let statusColor: Color
    @State private var showRatingSheet = false
    
    var isPastSession: Bool {
        session.sessionDate < Date()
    }
    
    var canRate: Bool {
        session.isAccepted && isPastSession && !session.isCompleted
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.subject)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("with \(session.tutorName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.sessionDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(session.duration) min • $\(Int(session.totalCost))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(session.status.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if let rating = session.rating {
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    if let review = session.review, !review.isEmpty {
                        Text("•")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(review)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            } else if canRate {
                Button(action: {
                    showRatingSheet = true
                }) {
                    HStack {
                        Image(systemName: "star")
                        Text("Rate this session")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            } else if session.isCompleted && session.rating == nil {
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showRatingSheet) {
            RatingSheet(session: session, isPresented: $showRatingSheet)
        }
    }
}

struct RatingSheet: View {
    let session: Session
    @Binding var isPresented: Bool
    @State private var rating: Int = 5
    @State private var review: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("How was your session?")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(session.subject) with \(session.tutorName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("Rating")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                            }
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    Text("Review (Optional)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextEditor(text: $review)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: submitRating) {
                    Text(isSubmitting ? "Submitting..." : "Submit Rating")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(isSubmitting)
            }
            .padding()
            .navigationTitle("Rate Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
    
    func submitRating() {
        isSubmitting = true
        Task {
            await SessionManager.shared.rateSession(session, rating: rating, review: review)
            await MainActor.run {
                isSubmitting = false
                isPresented = false
            }
        }
    }
}

struct Tutor {
    let name: String
    let subject: String
    let rating: Double
    let price: Int
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
