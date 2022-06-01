//
//  SyncContentView.swift
//  RealmTest
//
//  Created by nicola cabiddu on 09/03/2022.
//

import SwiftUI
import RealmSwift

struct LoadShapesView: View {
    @State var user: User?
    @State var errorMessage: String?
    
    var body: some View {
        
        VStack {
            if let user = self.user {
                SyncShapesView().environment(\.realmConfiguration, user.flexibleSyncConfiguration())
            }
            else {
                Button("Load Shapes") {
                    Task {
                        do {
                            app.syncManager.logLevel = .all;
                            self.user = try await app.login(credentials: .anonymous)
                        }
                        catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
                if let errorMessage = self.errorMessage {
                    Text("Error \(errorMessage)")
                }
            }
        }.padding().navigationTitle("Load Shapes")
    }
}


