import SwiftUI

struct MessagesView: View {
    @State private var searchText = ""
    

    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Chats")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .ignoresSafeArea(.all, edges: .top)
        }
        .navigationBarHidden(true)
    }
    

    var currentUserSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("User")
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 20)
    }
}

struct ChatRowView: View {
    let chat: ChatItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: chat.profileImage)
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(chat.timestamp)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

struct ChatDetailView: View {
    let chat: ChatItem
    
    var body: some View {
        VStack {
            Text("Chat with \(chat.name)")
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("Chat messages would appear here")
                .foregroundColor(.gray)
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatItem: Identifiable {
    let id: Int
    let name: String
    let lastMessage: String
    let timestamp: String
    let unreadCount: Int
    let profileImage: String
    var isCurrentUser: Bool = false
}

 struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
