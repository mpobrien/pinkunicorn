//
//  RealmTestApp.swift
//  RealmTest
//
//  Created by nicola cabiddu on 08/03/2022.
//

import SwiftUI
import RealmSwift



let appId = "pink-unicorn-bvzgq"
let app = RealmSwift.App(id: appId)

@main
struct RealmTestApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            LoadShapesView()
        }
    }
}
