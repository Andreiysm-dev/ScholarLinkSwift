import SwiftUI
import Supabase

class UserSession: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    
    static let shared = UserSession()
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        // Check if user is already logged in
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        do {
            let session = try await supabase.auth.session
            await fetchUserProfile(userId: session.user.id)
        } catch {
            print("No active session: \(error)")
            await MainActor.run {
                self.isLoggedIn = false
            }
        }
    }
    
    func fetchUserProfile(userId: UUID) async {
        do {
            let profile: User = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = profile
                self.isLoggedIn = true
            }
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }
    
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
    }
    
    func logout() async {
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isLoggedIn = false
            }
        } catch {
            print("Logout error: \(error)")
        }
    }
    
    var isCurrentUserTutor: Bool {
        return currentUser?.userRoleRaw == "tutor"
    }
    
    var isCurrentUserStudent: Bool {
        return currentUser?.userRoleRaw == "learner"
    }
}
