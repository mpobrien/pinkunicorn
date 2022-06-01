//
//  OpenSyncContentView.swift
//  RealmTest
//
//  Created by nicola cabiddu on 09/03/2022.
//

import SwiftUI
import RealmSwift

struct SyncShapesView: View {
    
    @State var isSynced : Bool = false
    @State var errorMessage: String?
    @State var numberObjects: Int = 0
    @Environment(\.realmConfiguration) var configuration
    
    var body : some View {
        
        VStack {
            
            if isSynced {
                RenderShapesView()
            }
            else {
                ProgressView()
                    .task {
                        do {
                            let realm = try await Realm(configuration: configuration, downloadBeforeOpen: .always)
                            let subs = realm.subscriptions
                            try await subs.write {
                                subs.append(QuerySubscription<Component>{
                                    $0.left > 0 && $0.right > 0 && $0.top > 0 && $0.bottom > 0
                                })
                            }
                            isSynced = true
                            numberObjects = realm.objects(Component.self).count
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
            }
            
            if let errorMessage = self.errorMessage {
                Text("Error \(errorMessage)")
            }
                
        }.padding().navigationTitle("Sync")
    }
}
