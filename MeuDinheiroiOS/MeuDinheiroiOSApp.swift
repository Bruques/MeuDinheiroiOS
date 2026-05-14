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
        
        // 2. Configura SwiftData
        do {
            container = try ModelContainer(for: Expense.self)
            
            // 3. Inicializa as camadas de dados
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
                    // Se estiver logado, vai direto para o Dashboard
                    DashboardView(repository: repository)
                        .environmentObject(syncManager)
                } else {
                    // Se não, pede login (passando um callback para atualizar o estado)
                    LoginView(authService: FirebaseAuthService(), repository: repository) {
                        self.isAuthenticated = true
                    }
                    .environmentObject(syncManager)
                }
            }
        }
        .modelContainer(container)
    }
}
