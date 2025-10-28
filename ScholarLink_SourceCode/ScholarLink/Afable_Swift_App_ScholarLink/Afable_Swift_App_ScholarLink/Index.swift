import SwiftUI

// HEADER
struct HeaderView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingNotifications = false
    @State private var showingSearch = false
    
    var currentUser: User? {
        return UserSession.shared.currentUser
    }
    
    var unreadCount: Int {
        guard let user = currentUser else { return 0 }
        return notificationManager.getUnreadCount(for: user.id)
    }
    
    var body: some View {
        HStack {
            HStack {
                HStack {
                    Text("Scholar")
                        .foregroundColor(.blue)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Link")
                        .foregroundColor(.black)
                        .font(.title)
                        .fontWeight(.bold)
                    Image(systemName: "graduationcap.fill")
                }
                .padding(.horizontal,15)
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.vertical, 10)
            .padding(.horizontal)
            Spacer()
                
            HStack {
                Button(action: {
                    showingSearch = true
                }) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .background(Color.black)
                        .cornerRadius(20)
                }
                
                // Notification bell with badge
                Button(action: {
                    showingNotifications = true
                }) {
                    ZStack {
                        Image(systemName: "bell.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .background(Color.black)
                            .cornerRadius(20)
                        
                        // Badge for unread notifications
                        if unreadCount > 0 {
                            Text("\(unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            .padding(.horizontal,10)
            
        }
        .background(Color.blue.shadow(radius: 100))
        .sheet(isPresented: $showingNotifications) {
            NotificationView()
        }
        .sheet(isPresented: $showingSearch) {
            NavigationStack {
                AllTutors()
            }
        }
    }
}


//NAVIGATION OF PAGES
struct IndexView: View {
    @StateObject private var userSession = UserSession.shared
    
    var body: some View {
        if userSession.currentUser == nil {
            ProgressView("Loading...")
        } else {
            VStack {
                HeaderView()
                TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                
                // TUTOR OR STUDENT DASHBOARD
                if userSession.isCurrentUserTutor {
                     TutorDashboardView()
                        .tabItem {
                            Image(systemName: "calendar.badge.clock")
                            Text("Sessions")
                        }
                } else {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "book")
                            Text("Dashboard")
                        }
                }
                
                MessagesView()
                    .tabItem {
                        Image(systemName: "bubble.left")
                        Text("Messages")
                    }
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
            }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        LandingView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
