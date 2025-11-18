import Foundation
import Supabase

struct VerificationUploadResult {
    let idImageURL: String?
    let credentialURL: String?
}

final class VerificationStorageManager {
    static let shared = VerificationStorageManager()
    private let client = SupabaseManager.shared.client
    private let bucketName = "tutor-verifications"
    
    private init() {}
    
    func uploadIDImage(_ data: Data, tutorId: UUID) async throws -> String {
        let fileName = "id-images/\(tutorId.uuidString)-\(UUID().uuidString).jpg"
        return try await upload(data: data, fileName: fileName, mimeType: "image/jpeg")
    }
    
    func uploadCredentialFile(_ data: Data, tutorId: UUID, fileExtension: String, mimeType: String) async throws -> String {
        let fileName = "credentials/\(tutorId.uuidString)-\(UUID().uuidString).\(fileExtension)"
        return try await upload(data: data, fileName: fileName, mimeType: mimeType)
    }
    
    private func upload(data: Data, fileName: String, mimeType: String) async throws -> String {
        let storage = client.storage.from(bucketName)
        try await storage.upload(fileName, data: data, options: FileOptions(contentType: mimeType, upsert: true))
        return storage.getPublicURL(path: fileName).absoluteString
    }
}

