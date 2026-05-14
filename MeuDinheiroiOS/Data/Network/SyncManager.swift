//
//  SyncManager.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 13/05/26.
//

import Foundation
import Network
import SwiftData
import Combine

@MainActor
class SyncManager: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // O SyncManager precisa do repositório para mandar sincronizar
    private var repository: ExpenseRepositoryProtocol?
    
    @Published var isOnline: Bool = true
    
    init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
        setupMonitor()
    }
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                // Atualiza o status da conexão
                let currentlyOnline = (path.status == .satisfied)
                self?.isOnline = currentlyOnline
                
                if currentlyOnline {
                    print("DEBUG: 🌐 Internet restaurada! Iniciando sincronização...")
                    try? await self?.repository?.syncOfflineExpenses()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // Método para forçar uma sincronização manual se necessário
    func forceSync() async {
        if isOnline {
            try? await repository?.syncOfflineExpenses()
        }
    }
}
