import SwiftUI
import Supabase

struct RegisterView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var registrationMessage = ""
    @State private var isRegistered = false
    @State private var registeredUser: User?

    private let supabase = SupabaseManager.shared.client

    var body: some View {
        ScrollView {
            VStack {
                Spacer(minLength: 90)
                
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

                VStack(spacing: 30) {
                    Text("Create your account")
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    TextField("Enter your email", text: $email)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                        .frame(maxWidth: 300)

                    TextField("Enter your Username", text: $username)
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

                    SecureField("Re-enter your password", text: $confirmPassword)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1))
                        .frame(maxWidth: 300)

                    Button(action: registerUser) {
                        Text("Register")
                            .font(.headline)
                            .padding(.vertical, 13)
                            .padding(.horizontal, 130)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    Text(registrationMessage)
                        .foregroundColor(registrationMessage == "User registered successfully!" ? .green : .red)
                        .font(.caption)

                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(.gray.opacity(0.8))

                        NavigationLink(destination: LoginView()) {
                            Text("Login")
                                .foregroundColor(.blue)
                        }
                        .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 350, alignment: .center)
        }
        .navigationDestination(isPresented: $isRegistered) {
            if let user = registeredUser {
                ProfileSetupView(user: user)
            }
        }
    }

    func registerUser() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedUsername.isEmpty, !trimmedPassword.isEmpty else {
            registrationMessage = "Please fill in all fields."
            return
        }

        guard trimmedPassword == trimmedConfirmPassword else {
            registrationMessage = "Passwords do not match."
            return
        }
        
        guard trimmedPassword.count >= 6 else {
            registrationMessage = "Password must be at least 6 characters."
            return
        }

        Task {
            do {
                // Sign up with Supabase Auth
                let authResponse = try await supabase.auth.signUp(
                    email: trimmedEmail,
                    password: trimmedPassword
                )
                
                // Small delay to ensure trigger completes
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Update profile with username
                let updateData: [String: Any] = ["username": trimmedUsername]
                let jsonData = try JSONSerialization.data(withJSONObject: updateData)
                try await supabase
                    .from("profiles")
                    .update(jsonData)
                    .eq("id", value: authResponse.user.id.uuidString)
                    .execute()
                
                let profile: User = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: authResponse.user.id.uuidString)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    registrationMessage = "User registered successfully!"
                    registeredUser = profile
                    isRegistered = true
                }
            } catch {
                await MainActor.run {
                    registrationMessage = "Registration failed: \(error.localizedDescription)"
                    print("Registration error: \(error)")
                }
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
