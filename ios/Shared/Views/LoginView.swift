import SwiftUI
import RealmSwift

struct LoginView: View {
    @State var user: User? = app.currentUser {
        didSet {
            isLoggout = user == nil ? true : false
        }
    }
    @State var isLoggout: Bool = false
    @State var errorMessage: String?

    @State var username: String = ""
    @State var password: String = ""

    var body: some View {
        VStack {
            NavigationLink(destination: Text("Please Login"), isActive: $isLoggout) {}
            if let user = self.user {
                AsyncView()
                    .environment(\.realmConfiguration, user.flexibleSyncConfiguration())
                Button("Logout") {
                    Task {
                        do {
                            _ = try await user.logOut()
                            self.user = nil
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            } else {
                Text("User Login")
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
                Spacer()
                Text("Admin Login")
                TextField("Username", text: $username)
                TextField("Password", text: $password)
                Button("Login") {
                    Task {
                        do {
                            app.syncManager.logLevel = .all
                            self.user = try await app.login(credentials: Credentials.emailPassword(email: username, password: password))
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
                Spacer()
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
                            guard subs.first(named: "offset") == nil else {
                                isSynced = true
                                return
                            }
                            try await subs.write {
                                subs.append(QuerySubscription<Component>(name: "offset") {
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
