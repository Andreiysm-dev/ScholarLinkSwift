import SwiftUI

struct MyBookingsView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var userSession = UserSession.shared
    @State private var sessionToRate: Session? = nil
    @State private var pendingRating: Int = 5
    @State private var pendingReview: String = ""

    var currentUser: User? { userSession.currentUser }
    var isTutor: Bool { userSession.isCurrentUserTutor }

    var studentAccepted: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForStudent(email: user.email).filter { $0.isAccepted && !$0.isCompleted }
    }

    var studentPending: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForStudent(email: user.email).filter { $0.isPending }
    }

    var studentCompleted: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForStudent(email: user.email).filter { $0.isCompleted }
    }

    var tutorPending: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForTutor(email: user.email).filter { $0.isPending }
    }

    var tutorAccepted: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForTutor(email: user.email).filter { $0.isAccepted && !$0.isCompleted }
    }

    var tutorCompleted: [Session] {
        guard let user = currentUser else { return [] }
        return sessionManager.getSessionsForTutor(email: user.email).filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            List {
                if isTutor {
                    if !tutorPending.isEmpty {
                        Section("Pending") {
                            ForEach(tutorPending) { session in
                                BookingRow(session: session, isTutor: true)
                            }
                        }
                    }
                    if !tutorAccepted.isEmpty {
                        Section("Upcoming") {
                            ForEach(tutorAccepted) { session in
                                BookingRow(session: session, isTutor: true)
                            }
                        }
                    }
                    if !tutorCompleted.isEmpty {
                        Section("Completed") {
                            ForEach(tutorCompleted) { session in
                                BookingRow(session: session, isTutor: true)
                            }
                        }
                    }
                } else {
                    if !studentPending.isEmpty {
                        Section("Pending") {
                            ForEach(studentPending) { session in
                                BookingRow(session: session, isTutor: false)
                            }
                        }
                    }
                    if !studentAccepted.isEmpty {
                        Section("Upcoming") {
                            ForEach(studentAccepted) { session in
                                BookingRow(session: session, isTutor: false)
                            }
                        }
                    }
                    if !studentCompleted.isEmpty {
                        Section("Completed") {
                            ForEach(studentCompleted) { session in
                                BookingRow(
                                    session: session,
                                    isTutor: false,
                                    showRate: session.rating == nil,
                                    onRate: { sessionToRate = session; pendingRating = 5; pendingReview = "" }
                                )
                            }
                        }
                    }
                }
            }
            .overlay(
                Group {
                    if (isTutor && tutorPending.isEmpty && tutorAccepted.isEmpty && tutorCompleted.isEmpty) ||
                       (!isTutor && studentPending.isEmpty && studentAccepted.isEmpty && studentCompleted.isEmpty) {
                        ContentUnavailableView("No bookings yet", systemImage: "calendar.badge.clock", description: Text("Book or accept sessions to see them here."))
                    }
                }
            )
            .navigationTitle("My Bookings")
            .refreshable {
                await sessionManager.loadSessions()
            }
            .sheet(item: $sessionToRate) { _ in
                RateSessionSheet(
                    session: $sessionToRate,
                    rating: $pendingRating,
                    review: $pendingReview,
                    onSubmit: {
                        if let s = sessionToRate {
                            Task {
                                await sessionManager.rateSession(s, rating: pendingRating, review: pendingReview)
                                await MainActor.run { sessionToRate = nil }
                            }
                        }
                    }
                )
            }
        }
    }
}

private struct BookingRow: View {
    let session: Session
    let isTutor: Bool
    var showRate: Bool = false
    var onRate: (() -> Void)? = nil

    var title: String {
        isTutor ? session.studentName : session.tutorName
    }

    var subtitle: String { session.subject }

    var statusText: String {
        if session.isCompleted { return "Completed" }
        if session.isPending { return "Pending" }
        if session.isAccepted { return "Accepted" }
        return session.status.capitalized
    }

    var statusColor: Color {
        if session.isCompleted { return .gray }
        if session.isPending { return .orange }
        if session.isAccepted { return .green }
        return .blue
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(statusText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(session.sessionDate.sessionDateFormat)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text(String(format: "PHP %.0f", session.hourlyRate))
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(String(format: "%.2f hrs", Double(session.duration) / 60.0))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "Total: PHP %.0f", session.totalCost))
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
                if showRate {
                    Button(action: { onRate?() }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Rate Session")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                } else if let r = session.rating {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= r ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        if let review = session.review, !review.isEmpty {
                            Text("\"\(review)\"")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct RateSessionSheet: View {
    @Binding var session: Session?
    @Binding var rating: Int
    @Binding var review: String
    var onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Rate Session")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title2)
                            .onTapGesture { rating = i }
                    }
                }
                TextField("Write a short review (optional)", text: $review, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { session = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { onSubmit() }
                        .disabled(rating < 1)
                }
            }
        }
    }
}
