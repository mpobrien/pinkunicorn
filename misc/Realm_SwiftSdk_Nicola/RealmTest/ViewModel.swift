////
////  Realm.swift
////  RealmTest
////
////  Created by nicola cabiddu on 08/03/2022.
////
//
//import Foundation
//import RealmSwift
//
//
//let app: RealmSwift.App? = RealmSwift.App(id: "pink-unicorn-bvzgq")
//
//
//
//
//
//
//class ViewModel : ObservableObject {
//    
//    dynamic let app = App(id: "pink-unicorn-bvzgq")
//    
//    func myAppBootstrap()
//    {
//        app.login(credentials: Credentials.anonymous) { (result) in
//            DispatchQueue.main.async {
//                switch result {
//                case .failure(let error):
//                    print("Login failed: \(error)")
//                    
//                case .success(let user):
//                    print("Login as \(user) succeeded!")
//                    self.onLogin()
//                }
//            }
//        }
//    }
//
//    func onLogin()
//    {
//        let user = app.currentUser!
//        let configuration = user.flexibleSyncConfiguration()
//        Realm.asyncOpen(configuration: configuration) { (result) in
//            switch result {
//            case .failure(let error):
//                print("Failed to open realm: \(error.localizedDescription)")
//                // Handle error...
//            case .success(let realm):
//                // Realm opened
//                self.onRealmOpened(realm)
//            }
//        }
//    }
//    
//    func onRealmOpened(_ realm: Realm) {
//        print("Open Realm")
//        print(realm.schema.objectSchema)
//        let components = realm.objects(Component.self)
//        print("Canvas components: \(components.count)")
//        for component in components {
//            print(component.objectSchema.description)
//        }
//    }
//};
