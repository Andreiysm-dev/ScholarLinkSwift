import SwiftUI

@main
struct YourAppName: App {
    @StateObject private var userSession = UserSession.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if userSession.isLoggedIn {
                    IndexView()
                        .id("logged_in")
                } else {
                    LandingView()
                        .id("logged_out")
                }
            }
            .task {
                SessionReminderScheduler.shared.requestAuthorizationIfNeeded()
            }
        }
    }
}
