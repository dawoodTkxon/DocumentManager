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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .modelContainer(for: CompanyModel.self)

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
    
    
}



