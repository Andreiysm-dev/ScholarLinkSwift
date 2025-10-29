import SwiftUI
import Supabase

struct ProfileSetupView: View {
    let user: User
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var bio = ""
    @State private var selectedRole: UserRole = .learner
    @State private var selectedSubjects: Set<String> = []
    @State private var hourlyRate = ""
    @State private var yearsExperience = ""
    @State private var setupMessage = ""
    @State private var isSetupComplete = false
    @State private var isLoading = false
    
    private let supabase = SupabaseManager.shared.client
    
    let availableSubjects = [
        "Mathematics", "Programming", "Science", "English",
        "History", "Physics", "Chemistry", "Biology",
        "Psychology", "Economics", "Art", "Music"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Complete Your Profile")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Let's set up your ScholarLink experience")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Basic Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TextField("First Name", text: $firstName)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: 300)
                        
                        TextField("Last Name", text: $lastName)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: 300)
                        
                        TextField("Tell us about yourself (optional)", text: $bio, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: 300)
                    }
                    
                    // Role Selection
                    VStack(alignment: .leading, spacing: 15) {
                        Text("How will you use ScholarLink?")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                RoleSelectionCard(
                                    role: role,
                                    isSelected: selectedRole == role
                                ) {
                                    selectedRole = role
                                }
                            }
                        }
                    }
                    
                    // Tutor-specific fields
                    if selectedRole == .tutor {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Tutor Information")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Subject Selection
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Select your expertise areas:")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                    ForEach(availableSubjects, id: \.self) { subject in
                                        SubjectTag(
                                            subject: subject,
                                            isSelected: selectedSubjects.contains(subject)
                                        ) {
                                            if selectedSubjects.contains(subject) {
                                                selectedSubjects.remove(subject)
                                            } else {
                                                selectedSubjects.insert(subject)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 15) {
                                VStack(alignment: .leading) {
                                    Text("Years of Experience")
                                        .font(.caption)
                                    TextField("0", text: $yearsExperience)
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Hourly Rate (PHP)")
                                        .font(.caption)
                                    TextField("50", text: $hourlyRate)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                                }
                            }
                            .frame(maxWidth: 300)
                        }
                    }
                    
                    Button {
                        Task {
                            await completeSetup()
                        }
                    } label: {
                        Text("Complete Setup")
                            .font(.headline)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 80)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                    
                    Text(setupMessage)
                        .foregroundColor(setupMessage.contains("Success") ? .green : .red)
                        .font(.caption)
                    
                    NavigationLink(
                        destination: IndexView(),
                        isActive: $isSetupComplete
                    ) {
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .onAppear {
                firstName = user.firstName
                lastName = user.lastName
                bio = user.bio
                selectedRole = user.userRole
                selectedSubjects = Set(user.selectedSubjects)
            }
        }
    }
    
    func completeSetup() async {
        guard !firstName.isEmpty, !lastName.isEmpty else {
            setupMessage = "Please fill in your name."
            return
        }
        
        // Create update payload struct
        struct ProfileUpdate: Codable {
            let first_name: String
            let last_name: String
            let bio: String
            let user_role: String
            let selected_subjects: [String]
            let is_profile_complete: Bool
            let hourly_rate: Double?
            let years_experience: Int?
        }
        
        var hourlyRateValue: Double? = nil
        var yearsExpValue: Int? = nil
        
        if selectedRole == .tutor {
            guard !selectedSubjects.isEmpty else {
                setupMessage = "Please select at least one subject area."
                return
            }
            
            guard let rate = Double(hourlyRate), rate > 0 else {
                setupMessage = "Please enter a valid hourly rate."
                return
            }
            
            guard let experience = Int(yearsExperience), experience >= 0 else {
                setupMessage = "Please enter valid years of experience."
                return
            }
            
            hourlyRateValue = rate
            yearsExpValue = experience
        }
        
        let updatePayload = ProfileUpdate(
            first_name: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            last_name: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            user_role: selectedRole.rawValue,
            selected_subjects: Array(selectedSubjects),
            is_profile_complete: true,
            hourly_rate: hourlyRateValue,
            years_experience: yearsExpValue
        )
        
        await MainActor.run {
            isLoading = true
            setupMessage = "Saving profile..."
        }
        
        Task {
            do {
                // Use RPC to call a stored procedure
                struct RPCParams: Encodable {
                    let p_user_id: String
                    let p_first_name: String
                    let p_last_name: String
                    let p_bio: String
                    let p_user_role: String
                    let p_selected_subjects: [String]
                    let p_hourly_rate: Double?
                    let p_years_experience: Int?
                }
                
                let params = RPCParams(
                    p_user_id: user.id.uuidString,
                    p_first_name: updatePayload.first_name,
                    p_last_name: updatePayload.last_name,
                    p_bio: updatePayload.bio,
                    p_user_role: updatePayload.user_role,
                    p_selected_subjects: updatePayload.selected_subjects,
                    p_hourly_rate: updatePayload.hourly_rate,
                    p_years_experience: updatePayload.years_experience
                )
                
                try await supabase.rpc("update_profile", params: params).execute()
                
                // Fetch updated profile
                let updatedProfile: User = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: user.id.uuidString)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    setupMessage = "Profile setup complete!"
                    UserSession.shared.login(user: updatedProfile)
                    isSetupComplete = true
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    setupMessage = "Failed to save profile. Please try again."
                    isLoading = false
                }
            }
        }
    }
    
    // Helper function for timeout
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// Supporting Views
struct RoleSelectionCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(role == .learner ? "Student" : "Tutor")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(role == .learner ? "Find tutors and learn new skills" : "Share your knowledge and help others")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.4), lineWidth: isSelected ? 2 : 1))
        }
    }
}

struct SubjectTag: View {
    let subject: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(subject)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview disabled - requires Supabase connection
        Text("ProfileSetupView Preview")
    }
}
