//
//  MeuDinheiroiOSApp.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import SwiftUI
import FirebaseCore
import SwiftData

@main
struct MeuDinheiroiOSApp: App {
    let container: ModelContainer
    let repository: ExpenseRepository
    let syncManager: SyncManager
    
    
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
            
        } catch {
            fatalError("Não foi possível inicializar o SwiftData: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(authService: FirebaseAuthService(),
                      repository: repository)
                        .environmentObject(syncManager)
        }
        .modelContainer(for: Expense.self)
    }
}
