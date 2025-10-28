import Foundation

enum UserRole: String, CaseIterable, Codable {
    case learner = "learner"
    case tutor = "tutor"
}

struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var username: String
    var firstName: String
    var lastName: String
    var bio: String
    var userRole: UserRole
    var selectedSubjects: [String]
    var hourlyRate: Double?
    var yearsExperience: Int?
    var isProfileComplete: Bool
    let createdAt: Date
    var updatedAt: Date
    
    // Custom decoder to handle null values from old database entries
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        userRole = try container.decode(UserRole.self, forKey: .userRole)
        selectedSubjects = try container.decodeIfPresent([String].self, forKey: .selectedSubjects) ?? []
        hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
        yearsExperience = try container.decodeIfPresent(Int.self, forKey: .yearsExperience)
        isProfileComplete = try container.decodeIfPresent(Bool.self, forKey: .isProfileComplete) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
        case userRole = "user_role"
        case selectedSubjects = "selected_subjects"
        case hourlyRate = "hourly_rate"
        case yearsExperience = "years_experience"
        case isProfileComplete = "is_profile_complete"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed property for backward compatibility
    var userRoleRaw: String {
        userRole.rawValue
    }
}
