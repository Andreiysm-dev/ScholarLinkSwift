import SwiftUI

struct ProfileView: View {
    @ObservedObject private var userSession = UserSession.shared
    @StateObject private var sessionManager = SessionManager.shared

    var currentUser: User? {
        return userSession.currentUser
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    if let user = currentUser {
                        ProfileHeader(user: user)
                        ProfileStats(user: user, sessions: sessionManager.sessions)
                        ProfileSubjects(user: user)
                        ProfileAbout(user: user)
                        ProfileDetails(user: user)
                    }
                }
                .padding()
            }

            LogoutButton(action: logout)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let user = currentUser {
                    NavigationLink(destination: ProfileSetupView(user: user)) {
                        Text("Edit")
                    }
                }
            }
        }
    }

    func logout() {
        Task {
            await userSession.logout()
        }
    }
}



struct ProfileHeader: View {
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )

            HStack(spacing: 8) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                NavigationLink(destination: ProfileSetupView(user: user)) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            Text(user.userRoleRaw.capitalized)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(user.userRole == .tutor ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .foregroundColor(user.userRole == .tutor ? .blue : .green)
                .cornerRadius(8)
        }
    }
}

struct ProfileStats: View {
    let user: User
    let sessions: [Session]

    var isTutor: Bool { user.userRole == .tutor }
    var completedCount: Int {
        if isTutor {
            return sessions.filter { $0.tutorEmail == user.email && $0.isCompleted }.count
        } else {
            return sessions.filter { $0.studentEmail == user.email && $0.isCompleted }.count
        }
    }
    var ratings: [Int] {
        sessions.filter { $0.tutorEmail == user.email }.compactMap { $0.rating }
    }
    var avgRating: Double {
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(completedCount)")
                        .font(.headline)
                }
                Spacer()
                if isTutor {
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= Int(round(avgRating)) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Text(String(format: "%.1f", avgRating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("(\(ratings.count))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ProfileSubjects: View {
    let user: User
    var body: some View {
        if !user.selectedSubjects.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Subjects")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(user.selectedSubjects, id: \.self) { subject in
                        Text(subject)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.top, 6)
        }
    }
}

struct ProfileAbout: View {
    let user: User
    var body: some View {
        if !user.bio.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.headline)
                Text(user.bio)
                    .font(.body)
            }
            .padding(.top, 6)
        }
    }
}

struct ProfileDetails: View {
    let user: User

    var body: some View {
        VStack(spacing: 8) {
            ProfileRow(label: "Email", value: user.email)
            ProfileRow(label: "Username", value: user.username)
            if let rate = user.hourlyRate {
                ProfileRow(label: "Hourly Rate", value: "PHP\(Int(rate))/hour")
            }
            if let yrs = user.yearsExperience {
                ProfileRow(label: "Experience", value: "\(yrs) years")
            }
        }
        .padding(.top, 10)
    }
}

struct LogoutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Logout")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
                .padding([.horizontal, .bottom])
        }
    }
}

struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ProfileView() }
    }
}
