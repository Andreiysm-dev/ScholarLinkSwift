import SwiftUI
import Supabase
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ProfileSetupView: View {
    let user: User
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var bio = ""
    @State private var selectedRole: UserRole = .learner
    @State private var selectedSubjects: Set<String> = []
    @State private var hourlyRate = ""
    @State private var yearsExperience = ""
    @State private var verificationIdType = ""
    @State private var verificationIdNumber = ""
    @State private var verificationDocumentURL = ""
    @State private var verificationReferenceContact = ""
    @State private var verificationIdImageURL = ""
    @State private var selectedIdImageItem: PhotosPickerItem?
    @State private var selectedIdImageData: Data?
    @State private var idImageSelectionState = ""
    @State private var credentialFileName = ""
    @State private var credentialFileData: Data?
    @State private var credentialFileMimeType = ""
    @State private var credentialFileExtension = ""
    @State private var showingCredentialImporter = false
    @State private var setupMessage = ""
    @State private var isSetupComplete = false
    @State private var isLoading = false
    
    private let supabase = SupabaseManager.shared.client
    
    let availableSubjects = [
        "Mathematics", "Programming", "Science", "English",
        "History", "Physics", "Chemistry", "Biology",
        "Psychology", "Economics", "Art", "Music"
    ]
    
    let idTypeOptions = [
        "Student ID",
        "Driver's License",
        "Passport",
        "UMID",
        "PRC ID",
        "National ID"
    ]
    
    private var allowedCredentialTypes: [UTType] {
        [.pdf, .image, .plainText, .data, .zip, .spreadsheet, .presentation]
    }
    
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
                            
                            verificationSection
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
                    
                    NavigationLink(isActive: $isSetupComplete) {
                        IndexView()
                    } label: {
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
                verificationIdType = user.verificationIdType ?? ""
                verificationIdNumber = user.verificationIdNumber ?? ""
                verificationIdImageURL = user.verificationIdImageURL ?? ""
                verificationDocumentURL = user.verificationDocumentURL ?? ""
                verificationReferenceContact = user.verificationReferenceContact ?? ""
                idImageSelectionState = verificationIdImageURL.isEmpty ? "No ID uploaded" : "Existing ID on file"
                if verificationDocumentURL.isEmpty {
                    credentialFileName = ""
                } else {
                    credentialFileName = URL(string: verificationDocumentURL)?.lastPathComponent ?? "Existing document"
                }
            }
        }
    }
    
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Verification")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Provide valid credentials so students can see a verified badge on your tutor profile.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 14) {
                Menu {
                    ForEach(idTypeOptions, id: \.self) { option in
                        Button(option) { verificationIdType = option }
                    }
                } label: {
                    HStack {
                        Text(verificationIdType.isEmpty ? "Select government ID type" : verificationIdType)
                            .foregroundColor(verificationIdType.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                }
                
                TextField("Government ID Number", text: $verificationIdNumber)
                    .keyboardType(.numbersAndPunctuation)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $selectedIdImageItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Upload government ID photo")
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.4), lineWidth: 1.5))
                    }
                    .onChange(of: selectedIdImageItem) { newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    selectedIdImageData = data
                                    idImageSelectionState = "Attached • \(formatBytes(data.count))"
                                }
                            }
                        }
                    }
                    
                    if !idImageSelectionState.isEmpty {
                        Text(idImageSelectionState)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let data = selectedIdImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .cornerRadius(10)
                    } else if selectedIdImageData == nil, !verificationIdImageURL.isEmpty, let url = URL(string: verificationIdImageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 140)
                                    .cornerRadius(10)
                            case .failure:
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        showingCredentialImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text(credentialFileName.isEmpty ? "Select supporting document" : "Replace \(credentialFileName)")
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.4), lineWidth: 1.5))
                    }
                    .fileImporter(isPresented: $showingCredentialImporter, allowedContentTypes: allowedCredentialTypes, allowsMultipleSelection: false) { result in
                        switch result {
                        case .success(let urls):
                            guard let url = urls.first else { break }
                            if url.startAccessingSecurityScopedResource() {
                                defer { url.stopAccessingSecurityScopedResource() }
                                do {
                                    let data = try Data(contentsOf: url)
                                    credentialFileData = data
                                    credentialFileName = url.lastPathComponent
                                    credentialFileExtension = url.pathExtension.isEmpty ? "bin" : url.pathExtension
                                    credentialFileMimeType = mimeType(for: credentialFileExtension)
                                } catch {
                                    setupMessage = "Failed to read file."
                                }
                            }
                        case .failure:
                            break
                        }
                    }
                    
                    if !credentialFileName.isEmpty {
                        Text("Attached: \(credentialFileName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                TextField("Reference Contact (advisor, dean, supervisor)", text: $verificationReferenceContact)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            }
            .frame(maxWidth: 320)
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.blue)
                Text("We’ll review these details to award a Verified Tutor badge. Students will see your verification status on your public profile.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
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
            let verification_status: String?
            let verification_id_type: String?
            let verification_id_number: String?
            let verification_id_image_url: String?
            let verification_document_url: String?
            let verification_reference_contact: String?
        }
        
        var hourlyRateValue: Double? = nil
        var yearsExpValue: Int? = nil
        var verificationStatusValue: TutorVerificationStatus? = nil
        var verificationIdTypeValue: String? = nil
        var verificationIdNumberValue: String? = nil
        var verificationIdImageValue: String? = verificationIdImageURL.isEmpty ? nil : verificationIdImageURL
        var verificationDocumentValue: String? = verificationDocumentURL.isEmpty ? nil : verificationDocumentURL
        var verificationReferenceValue: String? = nil
        
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
            
            let trimmedIdType = verificationIdType.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedIdNumber = verificationIdNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedReference = verificationReferenceContact.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedIdType.isEmpty else {
                setupMessage = "Please specify the ID type you will submit."
                return
            }
            
            guard !trimmedIdNumber.isEmpty else {
                setupMessage = "Please provide your government ID number."
                return
            }
            
            let hasIdImage = selectedIdImageData != nil || !verificationIdImageURL.isEmpty
            guard hasIdImage else {
                setupMessage = "Please upload a clear photo of your government ID."
                return
            }
            
            
            
            if selectedIdImageData != nil || credentialFileData != nil {
                await MainActor.run {
                    setupMessage = "Uploading verification files..."
                }
                
                do {
                    if let idData = selectedIdImageData {
                        verificationIdImageValue = try await VerificationStorageManager.shared.uploadIDImage(idData, tutorId: user.id)
                    }
                    if let credentialData = credentialFileData {
                        let ext = credentialFileExtension.isEmpty ? "bin" : credentialFileExtension
                        let mime = credentialFileMimeType.isEmpty ? "application/octet-stream" : credentialFileMimeType
                        verificationDocumentValue = try await VerificationStorageManager.shared.uploadCredentialFile(credentialData, tutorId: user.id, fileExtension: ext, mimeType: mime)
                    }
                } catch {
                    await MainActor.run {
                        #if DEBUG
                        setupMessage = "Upload failed: \(error.localizedDescription)"
                        #else
                        setupMessage = "Failed to upload verification files. Please try again."
                        #endif
                        isLoading = false
                    }
                    return
                }
            }
            
            guard !trimmedReference.isEmpty else {
                setupMessage = "Please provide a reference contact."
                return
            }
            
            hourlyRateValue = rate
            yearsExpValue = experience
            verificationStatusValue = .pendingReview
            verificationIdTypeValue = trimmedIdType
            verificationIdNumberValue = trimmedIdNumber
            verificationReferenceValue = trimmedReference
        }
        
        let updatePayload = ProfileUpdate(
            first_name: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            last_name: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            user_role: selectedRole.rawValue,
            selected_subjects: Array(selectedSubjects),
            is_profile_complete: true,
            hourly_rate: hourlyRateValue,
            years_experience: yearsExpValue,
            verification_status: verificationStatusValue?.rawValue,
            verification_id_type: verificationIdTypeValue,
            verification_id_number: verificationIdNumberValue,
            verification_id_image_url: verificationIdImageValue,
            verification_document_url: verificationDocumentValue,
            verification_reference_contact: verificationReferenceValue
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
                    let p_verification_status: String?
                    let p_verification_id_type: String?
                    let p_verification_id_number: String?
                    let p_verification_id_image_url: String?
                    let p_verification_document_url: String?
                    let p_verification_reference_contact: String?
                }
                
                let params = RPCParams(
                    p_user_id: user.id.uuidString,
                    p_first_name: updatePayload.first_name,
                    p_last_name: updatePayload.last_name,
                    p_bio: updatePayload.bio,
                    p_user_role: updatePayload.user_role,
                    p_selected_subjects: updatePayload.selected_subjects,
                    p_hourly_rate: updatePayload.hourly_rate,
                    p_years_experience: updatePayload.years_experience,
                    p_verification_status: updatePayload.verification_status,
                    p_verification_id_type: updatePayload.verification_id_type,
                    p_verification_id_number: updatePayload.verification_id_number,
                    p_verification_id_image_url: updatePayload.verification_id_image_url,
                    p_verification_document_url: updatePayload.verification_document_url,
                    p_verification_reference_contact: updatePayload.verification_reference_contact
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
                    #if DEBUG
                    setupMessage = "Save failed: \(error.localizedDescription)"
                    #else
                    setupMessage = "Failed to save profile. Please try again."
                    #endif
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
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func mimeType(for ext: String) -> String {
        let lower = ext.lowercased()
        switch lower {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "ppt", "pptx": return "application/vnd.ms-powerpoint"
        case "xls", "xlsx": return "application/vnd.ms-excel"
        case "txt": return "text/plain"
        case "zip": return "application/zip"
        default: return "application/octet-stream"
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
