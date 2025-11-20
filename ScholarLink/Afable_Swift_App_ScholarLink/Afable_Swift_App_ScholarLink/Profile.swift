import SwiftUI
import PhotosUI
import UIKit
import Supabase

struct ProfileView: View {
    @ObservedObject private var userSession = UserSession.shared
    @StateObject private var sessionManager = SessionManager.shared
    @State private var portfolioURLs: [String] = []
    @State private var portfolioPickerItem: PhotosPickerItem?
    @State private var previewPortfolioImages: [UIImage] = []
    private let supabase = SupabaseManager.shared.client

    var currentUser: User? {
        return userSession.currentUser
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color.blue.opacity(0.1), Color.white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if let user = currentUser {
                        ProfileHeader(user: user)
                        ProfileStats(user: user, sessions: sessionManager.sessions)
                        ProfileSubjects(user: user)
                        ProfileAbout(user: user)
                        if user.userRole == .tutor {
                            ProfilePortfolioSection(
                                portfolioURLs: portfolioURLs,
                                previewImages: previewPortfolioImages,
                                onRemoveImageAt: { index in
                                    guard index < portfolioURLs.count, let current = currentUser else { return }
                                    let newURLs = portfolioURLs.enumerated().filter { $0.offset != index }.map { $0.element }
                                    Task {
                                        do {
                                            _ = try await supabase
                                                .from("profiles")
                                                .update(["portfolio_image_urls": newURLs])
                                                .eq("id", value: current.id.uuidString)
                                                .execute()
                                            await MainActor.run {
                                                portfolioURLs = newURLs
                                            }
                                        } catch {
                                            #if DEBUG
                                            print("Failed to update portfolio_image_urls on remove:", error)
                                            #endif
                                        }
                                    }
                                },
                                onRemovePreviewAt: { index in
                                    guard index < previewPortfolioImages.count else { return }
                                    previewPortfolioImages.remove(at: index)
                                },
                                pickerItem: $portfolioPickerItem
                            )
                        }
                        ProfileDetails(user: user)
                        if user.userRole == .tutor {
                            TutorVerificationDetailCard(
                                status: user.verificationStatus,
                                idType: user.verificationIdType,
                                credentialLink: user.verificationDocumentURL,
                                referenceContact: user.verificationReferenceContact,
                                idImageLink: user.verificationIdImageURL,
                                showSensitiveLinks: true
                            )
                        }
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
        .onAppear {
            if let user = currentUser {
                portfolioURLs = user.portfolioImageURLs
            }
        }
        .onChange(of: portfolioPickerItem) { newItem in
            guard let newItem, let user = currentUser else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    do {
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                previewPortfolioImages.append(image)
                            }
                        }
                        let url = try await PortfolioStorageManager.shared.uploadImage(data, tutorId: user.id)
                        var newURLs = portfolioURLs
                        newURLs.append(url)
                        _ = try await supabase
                            .from("profiles")
                            .update(["portfolio_image_urls": newURLs])
                            .eq("id", value: user.id.uuidString)
                            .execute()
                        await MainActor.run {
                            // Replace local previews with the persisted URLs
                            previewPortfolioImages.removeAll()
                            portfolioURLs = newURLs
                        }
                    } catch {
                        #if DEBUG
                        print("Failed to update portfolio_image_urls on add:", error)
                        #endif
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
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Text(String(user.firstName.prefix(1) + user.lastName.prefix(1)))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
                if user.userRole == .tutor {
                    TutorVerificationBadge(status: user.verificationStatus)
                        .padding(4)
                }
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    NavigationLink(destination: ProfileSetupView(user: user)) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    Text(user.userRoleRaw.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(user.userRole == .tutor ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                        .foregroundColor(user.userRole == .tutor ? .blue : .green)
                        .cornerRadius(8)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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

struct ProfilePortfolioSection: View {
    let portfolioURLs: [String]
    let previewImages: [UIImage]
    let onRemoveImageAt: (Int) -> Void
    let onRemovePreviewAt: (Int) -> Void
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Portfolio")
                    .font(.headline)
                Spacer()
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Work")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }
            }

            if portfolioURLs.isEmpty && previewImages.isEmpty {
                Text("Showcase your best work here. Add a few images to help students know your style.")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Preview images (newly picked, may not have URLs yet)
                        ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 110)
                                    .clipped()
                                    .cornerRadius(12)
                                Button {
                                    onRemovePreviewAt(index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                                .padding(6)
                            }
                        }

                        // Persisted images from Supabase URLs
                        ForEach(Array(portfolioURLs.enumerated()), id: \.offset) { index, urlString in
                            ZStack(alignment: .topTrailing) {
                                if let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 160, height: 110)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 160, height: 110)
                                                .clipped()
                                                .cornerRadius(12)
                                        case .failure:
                                            Color.gray.opacity(0.2)
                                                .frame(width: 160, height: 110)
                                                .cornerRadius(12)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                                Button {
                                    onRemoveImageAt(index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                                .padding(6)
                            }
                        }
                    }
                }
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
