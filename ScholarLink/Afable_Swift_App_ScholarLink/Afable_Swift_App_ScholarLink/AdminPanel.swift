import SwiftUI
import Supabase

struct AdminPanelView: View {
    @State private var allUsers: [User] = []
    @State private var showingDeleteAlert = false
    @State private var userToDelete: User?
    @State private var isLoading = true
    private let supabase = SupabaseManager.shared.client
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 8) {
                    Text("Admin Panel")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("User Management")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 30) {
                        StatView(title: "Total Users", count: allUsers.count)
                        StatView(title: "Tutors", count: tutorCount)
                        StatView(title: "Students", count: studentCount)
                    }
                }
                .padding()
                
                NavigationLink(destination: TutorVerificationReviewView()) {
                    HStack {
                        Label("Review Tutor Verification", systemImage: "checkmark.seal")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(allUsers, id: \.id) { user in
                        UserRowView(user: user) {
                            userToDelete = user
                            showingDeleteAlert = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetchUsers()
            }
            .alert("Delete User", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let user = userToDelete {
                        deleteUser(user)
                    }
                }
            } message: {
                Text("Delete User?")
            }
        }
    }
    
    var tutorCount: Int {
        allUsers.filter { $0.userRoleRaw == "tutor" }.count
    }
    
    var studentCount: Int {
        allUsers.filter { $0.userRoleRaw == "learner" }.count
    }
    
    private func fetchUsers() async {
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
            print("Failed to fetch users: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func deleteUser(_ user: User) {
        Task {
            do {
                try await supabase
                    .from("profiles")
                    .delete()
                    .eq("id", value: user.id.uuidString)
                    .execute()
                
                await fetchUsers()
            } catch {
                print("Failed to delete user: \(error)")
            }
        }
    }
}


struct StatView: View {
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
            Text(title)

        }
    }
}

struct UserRowView: View {
    let user: User
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(roleColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("\(String(user.firstName.prefix(1)))\(String(user.lastName.prefix(1)))")
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    Text(user.userRoleRaw.isEmpty ? "No Role" : user.userRoleRaw)
                    Spacer()
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var roleColor: Color {
        switch user.userRoleRaw {
        case "tutor": return .blue
        case "learner": return .green
        default: return .orange
        }
    }
}


struct AdminPanelView_Previews: PreviewProvider {
    static var previews: some View {
        AdminPanelView()
    }
}
