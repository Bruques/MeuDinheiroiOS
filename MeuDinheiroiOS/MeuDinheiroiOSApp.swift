//
//  MeuDinheiroiOSApp.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import SwiftData

@main
struct MeuDinheiroiOSApp: App {
    let container: ModelContainer
    let repository: ExpenseRepository
    let syncManager: SyncManager
    @State private var isAuthenticated: Bool = false
    
    init() {
        FirebaseApp.configure()
        do {
            container = try ModelContainer(for: Expense.self)
            let network = NetworkService()
            let context = container.mainContext
            self.repository = ExpenseRepository(networkService: network, context: context)
            self.syncManager = SyncManager(repository: repository)
            _isAuthenticated = State(initialValue: Auth.auth().currentUser != nil)
        } catch {
            fatalError("Não foi possível inicializar o SwiftData: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    DashboardView(repository: repository)
                        .environmentObject(syncManager)
                } else {
                    LoginView(authService: FirebaseAuthService(), repository: repository) {
                        self.isAuthenticated = true
                    }
                    .environmentObject(syncManager)
                }
            }
            .onAppear {
                Auth.auth().addStateDidChangeListener { _, user in
                    self.isAuthenticated = (user != nil)
                }
            }
        }
        .modelContainer(container)
    }
}
