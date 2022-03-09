import SwiftUI
import RealmSwift

let appId = "pink-unicorn-bvzgq"
let app = RealmSwift.App(id: appId)

@main
struct PinkUnicornWhiteboardApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                LoginView()
            }
        }
    }
}
