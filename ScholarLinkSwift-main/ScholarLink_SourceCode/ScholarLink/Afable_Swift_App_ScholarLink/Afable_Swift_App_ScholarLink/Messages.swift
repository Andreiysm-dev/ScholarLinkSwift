import SwiftUI
import Foundation

// MARK: - Models
struct Conversation: Identifiable, Codable {
    let id: UUID
    let user1Id: UUID
    let user2Id: UUID
    let user1Name: String
    let user2Name: String
    var lastMessage: String?
    var lastMessageTime: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case user1Name = "user1_name"
        case user2Name = "user2_name"
        case lastMessage = "last_message"
        case lastMessageTime = "last_message_time"
        case createdAt = "created_at"
    }
    
    func otherUserName(currentUserId: UUID) -> String {
        return currentUserId == user1Id ? user2Name : user1Name
    }
    
    func otherUserId(currentUserId: UUID) -> UUID {
        return currentUserId == user1Id ? user2Id : user1Id
    }
}

struct Message: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let senderName: String
    let content: String
    var isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case content
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// MARK: - Messaging Manager
class MessagingManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [UUID: [Message]] = [:]
    
    static let shared = MessagingManager()
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        Task { await loadConversations() }
    }
    
    func loadConversations() async {
        guard let currentUser = UserSession.shared.currentUser else { return }
        do {
            let fetchedConversations: [Conversation] = try await supabase
                .from("conversations")
                .select()
                .or("user1_id.eq.\(currentUser.id.uuidString),user2_id.eq.\(currentUser.id.uuidString)")
                .order("last_message_time", ascending: false)
                .execute()
                .value
            await MainActor.run { self.conversations = fetchedConversations }
        } catch {
            print("Failed to load conversations: \(error)")
        }
    }
    
    func loadMessages(conversationId: UUID) async {
        do {
            let fetchedMessages: [Message] = try await supabase
                .from("messages")
                .select()
                .eq("conversation_id", value: conversationId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            await MainActor.run { self.messages[conversationId] = fetchedMessages }
        } catch {
            print("Failed to load messages: \(error)")
        }
    }
    
    func sendMessage(conversationId: UUID, content: String, senderId: UUID, senderName: String) async {
        struct NewMessage: Encodable {
            let conversation_id: String
            let sender_id: String
            let sender_name: String
            let content: String
        }
        let newMsg = NewMessage(conversation_id: conversationId.uuidString, sender_id: senderId.uuidString, sender_name: senderName, content: content)
        do {
            let created: Message = try await supabase.from("messages").insert(newMsg).select().single().execute().value
            await MainActor.run {
                if var msgs = self.messages[conversationId] {
                    msgs.append(created)
                    self.messages[conversationId] = msgs
                } else {
                    self.messages[conversationId] = [created]
                }
            }
            await loadConversations()
        } catch {
            print("Failed to send message: \(error)")
        }
    }
    
    func getOrCreateConversation(withUser: User, currentUser: User) async -> Conversation? {
        if let existing = conversations.first(where: { 
            ($0.user1Id == currentUser.id && $0.user2Id == withUser.id) || ($0.user1Id == withUser.id && $0.user2Id == currentUser.id)
        }) { return existing }
        struct NewConversation: Encodable {
            let user1_id: String; let user2_id: String; let user1_name: String; let user2_name: String
        }
        let newConv = NewConversation(user1_id: currentUser.id.uuidString, user2_id: withUser.id.uuidString, user1_name: "\(currentUser.firstName) \(currentUser.lastName)", user2_name: "\(withUser.firstName) \(withUser.lastName)")
        do {
            let created: Conversation = try await supabase.from("conversations").insert(newConv).select().single().execute().value
            await MainActor.run { self.conversations.insert(created, at: 0) }
            return created
        } catch {
            print("Failed to create conversation: \(error)")
            return nil
        }
    }
}

// MARK: - Views
struct MessagesView: View {
    @StateObject private var messagingManager = MessagingManager.shared
    var currentUser: User? { UserSession.shared.currentUser }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Chats").font(.largeTitle).fontWeight(.bold)
                    Spacer()
                }.padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
                
                if messagingManager.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 60)).foregroundColor(.gray.opacity(0.6))
                        Text("No Messages Yet").font(.headline).foregroundColor(.gray)
                        Text("Start a conversation with a tutor or student").font(.subheadline).foregroundColor(.gray.opacity(0.8)).multilineTextAlignment(.center)
                    }.padding()
                    Spacer()
                } else {
                    List {
                        ForEach(messagingManager.conversations) { conversation in
                            if let user = currentUser {
                                NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                                    ConversationRow(conversation: conversation, currentUserId: user.id)
                                }
                            }
                        }
                    }.listStyle(PlainListStyle())
                }
            }.onAppear { Task { await messagingManager.loadConversations() } }
        }.navigationBarHidden(true)
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: UUID
    var body: some View {
        HStack(spacing: 16) {
            Circle().fill(Color.blue.opacity(0.2)).frame(width: 50, height: 50)
                .overlay(Text(String(conversation.otherUserName(currentUserId: currentUserId).prefix(2))).font(.headline).foregroundColor(.blue).fontWeight(.bold))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName(currentUserId: currentUserId)).font(.headline).fontWeight(.semibold)
                    Spacer()
                    if let time = conversation.lastMessageTime {
                        Text(time.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundColor(.gray)
                    }
                }
                if let lastMsg = conversation.lastMessage {
                    Text(lastMsg).font(.subheadline).foregroundColor(.gray).lineLimit(1)
                }
            }
        }.padding(.vertical, 8)
    }
}

struct ChatDetailView: View {
    let conversation: Conversation
    @StateObject private var messagingManager = MessagingManager.shared
    @State private var messageText = ""
    var currentUser: User? { UserSession.shared.currentUser }
    var messages: [Message] { messagingManager.messages[conversation.id] ?? [] }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.senderId == currentUser?.id { Spacer() }
                            Text(message.content).padding().background(message.senderId == currentUser?.id ? Color.blue : Color.gray.opacity(0.2)).foregroundColor(message.senderId == currentUser?.id ? .white : .primary).cornerRadius(16)
                            if message.senderId != currentUser?.id { Spacer() }
                        }
                    }
                }.padding()
            }
            HStack {
                TextField("Message", text: $messageText).textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    guard let user = currentUser, !messageText.isEmpty else { return }
                    Task {
                        await messagingManager.sendMessage(conversationId: conversation.id, content: messageText, senderId: user.id, senderName: "\(user.firstName) \(user.lastName)")
                        messageText = ""
                    }
                }.disabled(messageText.isEmpty)
            }.padding()
        }.navigationTitle(conversation.otherUserName(currentUserId: currentUser?.id ?? UUID())).navigationBarTitleDisplayMode(.inline).onAppear { Task { await messagingManager.loadMessages(conversationId: conversation.id) } }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View { MessagesView() }
}
