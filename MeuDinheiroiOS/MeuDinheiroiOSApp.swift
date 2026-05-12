//
//  MeuDinheiroiOSApp.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import SwiftUI
import FirebaseCore

@main
struct MeuDinheiroiOSApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(authService: FirebaseAuthService())
        }
    }
}
