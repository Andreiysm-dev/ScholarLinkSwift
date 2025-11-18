import SwiftUI
import Supabase

struct TutorVerificationReviewView: View {
    @State private var tutors: [User] = []
    @State private var isLoading = false
    @State private var statusMessage = ""
    @State private var filter: Filter = .pending
    private let supabase = SupabaseManager.shared.client
    
    enum Filter: String, CaseIterable, Identifiable {
        case pending = "Pending"
        case verified = "Verified"
        case needsInfo = "Not Submitted"
        case all = "All"
        
        var id: String { rawValue }
        
        func matches(_ user: User) -> Bool {
            switch self {
            case .pending:
                return user.verificationStatus == .pendingReview
            case .verified:
                return user.verificationStatus == .verified
            case .needsInfo:
                return user.verificationStatus == .notSubmitted
            case .all:
                return true
            }
        }
    }
    
    var filteredTutors: [User] {
        tutors
            .filter { $0.userRole == .tutor }
            .filter { filter.matches($0) }
            .sorted { $0.firstName < $1.firstName }
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading tutor submissions...")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            ForEach(filteredTutors, id: \.id) { tutor in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(tutor.firstName) \(tutor.lastName)")
                                .font(.headline)
                            Text(tutor.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        TutorVerificationBadge(status: tutor.verificationStatus)
                    }
                    
                    TutorVerificationDetailCard(
                        status: tutor.verificationStatus,
                        idType: tutor.verificationIdType,
                        credentialLink: tutor.verificationDocumentURL,
                        referenceContact: tutor.verificationReferenceContact,
                        idImageLink: tutor.verificationIdImageURL,
                        showSensitiveLinks: true
                    )
                    
                    HStack {
                        Button(role: .destructive) {
                            Task { await updateStatus(for: tutor, to: .notSubmitted) }
                        } label: {
                            Label("Request Resubmission", systemImage: "arrow.uturn.backward")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button {
                            Task { await updateStatus(for: tutor, to: .verified) }
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 8)
            }
            
            if filteredTutors.isEmpty && !isLoading {
                Text("No tutor submissions for this filter.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .navigationTitle("Tutor Verification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $filter) {
                    ForEach(Filter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 320)
            }
        }
        .task {
            await fetchTutors()
        }
        .refreshable {
            await fetchTutors()
        }
        .alert("Verification Update", isPresented: Binding(get: {
            !statusMessage.isEmpty
        }, set: { value in
            if !value {
                statusMessage = ""
            }
        })) {
            Button("OK") {
                statusMessage = ""
            }
        } message: {
            Text(statusMessage)
        }
    }
    
    private func fetchTutors() async {
        await MainActor.run {
            isLoading = true
        }
        do {
            let fetched: [User] = try await supabase
                .from("profiles")
                .select()
                .eq("user_role", value: "tutor")
                .execute()
                .value
            
            await MainActor.run {
                tutors = fetched
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                statusMessage = "Failed to load tutors: \(error.localizedDescription)"
            }
        }
    }
    
    private func updateStatus(for tutor: User, to status: TutorVerificationStatus) async {
        do {
            try await supabase
                .from("profiles")
                .update(["verification_status": status.rawValue])
                .eq("id", value: tutor.id.uuidString)
                .execute()
            
            await fetchTutors()
            await MainActor.run {
                statusMessage = "\(tutor.firstName)'s status updated to \(status.label)."
            }
        } catch {
            await MainActor.run {
                statusMessage = "Failed to update tutor: \(error.localizedDescription)"
            }
        }
    }
}

