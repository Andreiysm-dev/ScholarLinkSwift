import SwiftUI
import Supabase

struct AllTutors: View {
    @State private var tutors: [User] = []
    @State private var isLoading = true
    private let supabase = SupabaseManager.shared.client
    
    let allSubjects = [
        "All", "Mathematics", "Programming", "Science", "English",
        "History", "Physics", "Chemistry", "Biology",
        "Psychology", "Economics", "Art", "Music"
    ]
    
    @State private var selectedSubject: String = "All"
    @State private var searchText: String = ""
    @State private var sortBy: SortOption = .name
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case rateAsc = "Rate: Low to High"
        case rateDesc = "Rate: High to Low"
        case experience = "Experience"
    }
    
    var filteredTutors: [User] {
        let filtered = tutors.filter { tutor in
            (selectedSubject == "All" || tutor.selectedSubjects.contains(selectedSubject)) &&
            (searchText.isEmpty ||
             tutor.firstName.localizedCaseInsensitiveContains(searchText) ||
             tutor.lastName.localizedCaseInsensitiveContains(searchText) ||
             tutor.selectedSubjects.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            )
        }
        
        return filtered.sorted { tutor1, tutor2 in
            switch sortBy {
            case .name:
                return tutor1.firstName < tutor2.firstName
            case .rateAsc:
                return (tutor1.hourlyRate ?? 0) < (tutor2.hourlyRate ?? 0)
            case .rateDesc:
                return (tutor1.hourlyRate ?? 0) > (tutor2.hourlyRate ?? 0)
            case .experience:
                return (tutor1.yearsExperience ?? 0) > (tutor2.yearsExperience ?? 0)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search tutors or subjects...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(allSubjects, id: \.self) { subject in
                            Button(action: {
                                selectedSubject = subject
                            }) {
                                Text(subject)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedSubject == subject ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedSubject == subject ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if filteredTutors.isEmpty {
                    Text("No tutors found.")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredTutors, id: \.id) { tutor in
                            NavigationLink(destination: TutorDetailView(tutor: tutor)) {
                                ImprovedTutorCard(tutor: tutor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("All Tutors")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchTutors()
        }
    }
    
    init(selectedSubject: String = "All") {
        self._selectedSubject = State(initialValue: selectedSubject)
    }

    private func fetchTutors() async {
        do {
            let fetchedTutors: [User] = try await supabase
                .from("profiles")
                .select()
                .eq("user_role", value: "tutor")
                .eq("is_profile_complete", value: true)
                .execute()
                .value
            
            await MainActor.run {
                self.tutors = fetchedTutors
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch tutors: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
