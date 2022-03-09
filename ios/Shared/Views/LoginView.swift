import SwiftUI
import RealmSwift

struct LoginView: View {
    @State var user: User?
    @State var errorMessage: String?

    var body: some View {
        VStack {
            if let user = self.user {
                AsyncView()
                    .environment(\.realmConfiguration, user.flexibleSyncConfiguration())
            } else {
                Button("Login") {
                    Task {
                        do {
                            app.syncManager.logLevel = .all
                            self.user = try await app.login(credentials: .anonymous)
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
                if let errorMessage = self.errorMessage {
                    Text("Error: \(errorMessage)")
                }
            }
        }
        .padding()
        .navigationTitle("Logging View")
    }
}

struct AsyncView: View {
    @State var isSynced: Bool = false
    @State var errorMessage: String?
    @Environment(\.realmConfiguration) var configuration

    var body: some View {
        VStack {
            NavigationLink(destination: CanvasView()
                            .environment(\.realmConfiguration, configuration), isActive: $isSynced) {}
            if isSynced {
                Text("Synced")
            } else {
                ProgressView()
                    .task {
                        do {
                            let realm = try await Realm(configuration: configuration, downloadBeforeOpen: .always)
                            let subs = realm.subscriptions
                            try await subs.write {
                                subs.append(QuerySubscription<Component> {
                                    $0.left < UIScreen.main.bounds.width && $0.right > 0 && $0.top < UIScreen.main.bounds.height && $0.bottom > 0
                                })
                            }
                            isSynced = true
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
            }
            if let errorMessage = self.errorMessage {
                Text("Error: \(errorMessage)")
            }
        }
        .padding()
        .navigationTitle("Logging View")
    }
}
