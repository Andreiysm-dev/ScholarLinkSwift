import Foundation
import Supabase

final class PortfolioStorageManager {
    static let shared = PortfolioStorageManager()
    private let client = SupabaseManager.shared.client
    private let bucketName = "tutor-portfolio"
    
    private init() {}
    
    func uploadImage(_ data: Data, tutorId: UUID) async throws -> String {
        let fileName = "portfolio/\(tutorId.uuidString)-\(UUID().uuidString).jpg"
        let storage = client.storage.from(bucketName)
        try await storage.upload(
            fileName,
            data: data,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
        return try storage.getPublicURL(path: fileName).absoluteString
    }
}
