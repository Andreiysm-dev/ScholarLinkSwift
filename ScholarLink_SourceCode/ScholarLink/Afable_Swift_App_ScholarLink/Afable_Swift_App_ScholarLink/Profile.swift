import SwiftUI

struct ProfileView: View {
    @ObservedObject private var userSession = UserSession.shared

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
                        ProfileDetails(user: user)
                    }
                }
                .padding()
            }

            LogoutButton(action: logout)
        }
        .navigationBarTitleDisplayMode(.inline)
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

            Text("\(user.firstName) \(user.lastName)")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

struct ProfileDetails: View {
    let user: User

    var body: some View {
        VStack(spacing: 8) {
            ProfileRow(label: "Email", value: user.email)
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
