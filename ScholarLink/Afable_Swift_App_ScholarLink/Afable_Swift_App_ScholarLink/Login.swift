import SwiftUI
import Supabase

struct LoginView: View {
    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var loginMessage = ""
    @State private var isLoggedIn = false
    @State private var isAdminLogin = false
    
    private let supabase = SupabaseManager.shared.client
    
    var body: some View {
            ScrollView {
                VStack {
                    Spacer(minLength: 100)
                    
                    HStack {
                        Text("Scholar")
                            .foregroundColor(.blue)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Link")
                            .foregroundColor(.black)
                            .font(.title)
                            .fontWeight(.bold)
                        Image(systemName: "graduationcap.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 20) {
                        Text("Login to your account")
                            .font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                        
                        TextField("Enter your email or username", text: $emailOrUsername)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: 300)
                        
                        SecureField("Enter your password", text: $password)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: 300)
                        
                        Button(action: loginUser) {
                            Text("Login")
                                .font(.headline)
                                .padding(.vertical, 13)
                                .padding(.horizontal, 130)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Text(loginMessage)
                            .foregroundColor(loginMessage == "Login successful!" ? .green : .red)
                            .font(.caption)
                        
                        HStack {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(.gray.opacity(0.8))
                            
                            NavigationLink(destination: RegisterView()) {
                                Text("Register")
                                    .foregroundColor(.blue)
                            }
                            .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, minHeight: 350, alignment: .center)
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                IndexView()
            }
            .navigationDestination(isPresented: $isAdminLogin) {
                AdminPanelView()
            }
    }
    
    func loginUser() {
        let trimmedInput = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty, !trimmedPassword.isEmpty else {
            loginMessage = "Please fill in all fields."
            return
        }
        
        // Check for admin login
        if trimmedInput == "admin@email.com" && trimmedPassword == "admin" {
            loginMessage = "Admin login successful!"
            isAdminLogin = true
            return
        }
        
        Task {
            do {
                // Sign in with Supabase Auth (only accepts email)
                let authResponse = try await supabase.auth.signIn(
                    email: trimmedInput,
                    password: trimmedPassword
                )
                
                // Fetch user profile
                let profile: User = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: authResponse.user.id.uuidString)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    print("✅ Login successful for: \(profile.email)")
                    loginMessage = "Login successful!"
                    UserSession.shared.login(user: profile)
                    isLoggedIn = true
                }
            } catch {
                await MainActor.run {
                    print(" Login failed: \(error)")
                    loginMessage = "Invalid credentials. Please try again."
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
