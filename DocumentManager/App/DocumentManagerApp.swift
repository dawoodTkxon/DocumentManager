//
//  DocumentManagerApp.swift
//  DocumentManager
//
//  Created by TKXON on 04/01/2025.
//

import SwiftUI
import SwiftData

import GoogleSignIn
import GoogleAPIClientForREST
import SwiftUI

@available(iOS 17, *)
@main
struct DocumentManagerApp: App {
    @StateObject private var vm = CloudKitViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    //    let sceneDelegate = MySceneDelegate()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CompanyModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(vm)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .modelContainer(sharedModelContainer)
//                            .withHostingWindow { window in
//                                sceneDelegate.originalDelegate = window?.windowScene.delegate
//                                window?.windowScene.delegate = sceneDelegate
//                            }
            
            
            //            ContentView().environmentObject(shareDataStore)
            //                          .withHostingWindow { window in
            //                             sceneDelegate.originalDelegate = window?.windowScene.delegate
            //                             window?.windowScene.delegate = sceneDelegate
            //                          }
            //
            
            
        }
        
    }
}

import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool{
        // FirebaseApp.configure()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}


//class MySceneDelegate : NSObject, UIWindowSceneDelegate {
//   var originalDelegate: UISceneDelegate?
//
//   func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata) {
//
//       // your code here
//   }
//
//   // forward all other UIWindowSceneDelegate/UISceneDelegate callbacks to original, like
//   func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//       originalDelegate?.scene(scene, willConnectTo: session, options: connectionOptions)
//   }
//}
