import SwiftUI
import Supabase

struct HomeView: View {
    @State private var tutors: [User] = []
    @State private var allUsers: [User] = []
    @State private var showAllTopics = false
    @State private var showAllTutors = false
    @State private var isLoading = true
    private let supabase = SupabaseManager.shared.client
    

    let allSubjects = [
        "Mathematics", "Programming", "Science", "English",
        "History", "Physics", "Chemistry", "Biology",
        "Psychology", "Economics", "Art", "Music"
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tutoring for Students, by Students")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("Study with your peers!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // FEATURED SERVICES
                VStack(alignment: .leading, spacing: 16) {
                    Text("Learning Options")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            NavigationLink(destination: PersonalTutorListView()) {
                                ImprovedFeatureCard(
                                    title: "Personal Tutor",
                                    subtitle: "1-on-1 sessions",
                                    icon: "person.circle.fill",
                                    color: .blue
                                )
                            }
                            NavigationLink(destination: TutoringCentersView()) {
                                ImprovedFeatureCard(
                                    title: "Tutoring Centers",
                                    subtitle: "Group learning",
                                    icon: "building.2.fill",
                                    color: .green
                                )
                            }
                            NavigationLink(destination: SelfLearningView()) {
                                ImprovedFeatureCard(
                                    title: "Self Learning",
                                    subtitle: "Study resources",
                                    icon: "book.fill",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // POPULAR TOPICS
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Popular Topics")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAllTopics.toggle()
                            }
                        }) {
                            Text(showAllTopics ? "Show Less" : "View All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if showAllTopics {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(allSubjects, id: \.self) { subject in
                                NavigationLink(destination: AllTutors(selectedSubject: subject)) {
                                    ImprovedTopicCard(
                                        topic: subject,
                                        tutorCount: getTutorCount(for: subject),
                                        icon: getSubjectIcon(for: subject),
                                        color: getSubjectColor(for: subject)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(allSubjects.prefix(5)), id: \.self) { subject in
                                    NavigationLink(destination: AllTutors(selectedSubject: subject)) {
                                        ImprovedTopicCard(
                                            topic: subject,
                                            tutorCount: getTutorCount(for: subject),
                                            icon: getSubjectIcon(for: subject),
                                            color: getSubjectColor(for: subject)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                    
                // RECOMMENDED TUTORS
                VStack(alignment: .leading, spacing: 16) {
                    HStack{
                        Text("Recommended Tutors")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        NavigationLink(destination: AllTutors()) {
                            Text("View All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)


                    }
                    
                    if showAllTutors {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(tutors, id: \.id) { tutor in
                                NavigationLink(destination: TutorDetailView(tutor: tutor)) {
                                    ImprovedTutorCard(tutor: tutor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(tutors.prefix(5), id: \.id) { tutor in
                                    NavigationLink(destination: TutorDetailView(tutor: tutor)) {
                                        ImprovedTutorCard(tutor: tutor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .task {
            await fetchData()
        }
    }
    
    private func fetchData() async {
        await fetchTutors()
        await fetchAllUsers()
    }
    
    private func fetchTutors() async {
        do {
            let fetchedTutors: [User] = try await supabase
                .from("profiles")
                .select()
                .eq("user_role", value: "tutor")
                .eq("is_profile_complete", value: true)
                .execute()
                .value
            
            await MainActor.run {
                self.tutors = fetchedTutors
            }
        } catch {
            print("Failed to fetch tutors: \(error)")
        }
    }
    
    private func fetchAllUsers() async {
        do {
            let users: [User] = try await supabase
                .from("profiles")
                .select()
                .execute()
                .value
            
            await MainActor.run {
                self.allUsers = users
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch all users: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func getSubjectIcon(for subject: String) -> String {
        switch subject {
        case "Mathematics": return "function"
        case "Programming": return "laptopcomputer"
        case "Science": return "atom"
        case "English": return "book.closed"
        case "History": return "clock"
        case "Physics": return "waveform"
        case "Chemistry": return "testtube.2"
        case "Biology": return "leaf"
        case "Psychology": return "brain.head.profile"
        case "Economics": return "chart.line.uptrend.xyaxis"
        case "Art": return "paintbrush"
        case "Music": return "music.note"
        default: return "book"
        }
    }
    
    func getSubjectColor(for subject: String) -> Color {
        switch subject {
        case "Mathematics": return .blue
        case "Programming": return .green
        case "Science": return .purple
        case "English": return .orange
        case "History": return .brown
        case "Physics": return .indigo
        case "Chemistry": return .mint
        case "Biology": return .green
        case "Psychology": return .pink
        case "Economics": return .yellow
        case "Art": return .red
        case "Music": return .cyan
        default: return .gray
        }
    }
    
    func getTutorCount(for subject: String) -> Int {
        return allUsers.filter { user in
            user.userRoleRaw == "tutor"
            && user.isProfileComplete
            && user.selectedSubjects.contains(subject)
        }.count
    }
}

// IMPROVED COMPONENTS

struct ImprovedFeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 140, height: 120)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ImprovedTopicCard: View {
    let topic: String
    let tutorCount: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(tutorCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(topic)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(tutorCount) tutors available")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ImprovedTutorCard: View {
    let tutor: User
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text("\(String(tutor.firstName.prefix(1)))\(String(tutor.lastName.prefix(1)))")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                )
            
            VStack(spacing: 6) {
                Text("\(tutor.firstName) \(tutor.lastName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(tutor.yearsExperience ?? 0) years exp")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("PHP\(Int(tutor.hourlyRate ?? 0))/hr")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                if let firstSubject = tutor.selectedSubjects.first {
                    Text(firstSubject)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .frame(width: 140, height: 160)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}



struct RealTutorCard: View { // COMPONENT FOR TUTOR DISPLAY
    let tutor: User
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text("\(String(tutor.firstName.prefix(1)))\(String(tutor.lastName.prefix(1)))")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                )
            
            Text("\(tutor.firstName) \(tutor.lastName)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text("\(tutor.yearsExperience) years exp")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("PHP\(Int(tutor.hourlyRate ?? 0))/hr")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            
            if !tutor.selectedSubjects.isEmpty {
                Text(tutor.selectedSubjects.prefix(2).joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 130)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .shadow(radius: 2))
    }
}


struct PersonalTutorListView: View {
    var body: some View {
        Text("Personal Tutor List")
            .navigationTitle("Personal Tutors")
    }
}

struct TutoringCentersView: View {
    var body: some View {
        Text("Tutoring Centers")
            .navigationTitle("Tutoring Centers")
    }
}

struct SelfLearningView: View {
    var body: some View {
        Text("Self Learning")
            .navigationTitle("Self Learning")
    }
}

struct TutorDetailView: View { // TUTOR PROFILE FOR BOOKING
    let tutor: User
    @StateObject private var sessionManager = SessionManager.shared
    private let supabase = SupabaseManager.shared.client
    @State private var tutorRatings: [Int] = []
    
    var currentUser: User? {
        return UserSession.shared.currentUser
    }
    var hasPendingSession: Bool {
        guard let user = currentUser else { return false }
        let studentSessions = sessionManager.getSessionsForStudent(email: user.email)
        return studentSessions.contains { session in
            session.tutorEmail == tutor.email && session.isPending
        }
    }
    
    var pendingSession: Session? {
        guard let user = currentUser else { return nil }
        let studentSessions = sessionManager.getSessionsForStudent(email: user.email)
        return studentSessions.first { session in
            session.tutorEmail == tutor.email && session.isPending
        }
    }
    var averageRating: Double {
        guard !tutorRatings.isEmpty else { return 0 }
        let total = tutorRatings.reduce(0, +)
        return Double(total) / Double(tutorRatings.count)
    }
    
    func fetchTutorRatings() async {
        do {
            let sessions: [Session] = try await supabase
                .from("sessions")
                .select()
                .eq("tutor_id", value: tutor.id.uuidString)
                .execute()
                .value
            let ratings = sessions.compactMap { $0.rating }
            await MainActor.run {
                self.tutorRatings = ratings
            }
        } catch {
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("\(String(tutor.firstName.prefix(1)))\(String(tutor.lastName.prefix(1)))")
                                .font(.title)
                                .foregroundColor(.blue)
                                .fontWeight(.bold)
                        )
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(tutor.firstName) \(tutor.lastName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(tutor.yearsExperience ?? 0) years of experience")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("PHP \(Int(tutor.hourlyRate ?? 0))/hour")
                            .font(.headline)
                            .foregroundColor(.green)
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= Int(round(averageRating)) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            Text(String(format: "%.1f", averageRating))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("(\(tutorRatings.count))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                if !tutor.bio.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                        Text(tutor.bio)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Areas of expertise")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(tutor.selectedSubjects, id: \.self) { subject in
                            Text(subject)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    if hasPendingSession {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Session Request Pending")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                            
                            if let session = pendingSession {
                                Text("Waiting for \(tutor.firstName) to respond to your \(session.subject) session request")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    } else {
                        NavigationLink(destination: BookSessionView(tutor: tutor)) {
                            Text("Book Session")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                    }) {
                        Text("Contact Tutor")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Tutor Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchTutorRatings()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
