//
//  ExpenseRepository.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation
import SwiftData
import FirebaseAuth

class ExpenseRepository: ExpenseRepositoryProtocol {
    private let networkService: NetworkService
    private let context: ModelContext
    private var isSyncing = false
    
    init(networkService: NetworkService, context: ModelContext) {
        self.networkService = networkService
        self.context = context
    }
    
    // MARK: - Salvar Despesa (A Mágica do Offline)
    func saveExpense(_ expense: Expense) async throws {
        // 1. OFFLINE-FIRST: Salva no celular imediatamente
        context.insert(expense)
        try? context.save()
        
        // 2. Tenta mandar pra nuvem em segundo plano
        do {
            // Pega o token de forma segura do Firebase
            let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
            
            try await networkService.postExpense(expense, token: token)
            
            // 3. Se a internet estava boa e não deu erro no backend, marca como sincronizado!
            expense.syncStatus = .synced
            try? context.save()
            
        } catch {
            // SEM INTERNET: Nós apenas capturamos o erro e ignoramos!
            // O app não trava, o usuário não vê erro, e o item fica salvo no celular com status '.pending'.
            print("DEUB: Salvo apenas offline. Motivo: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Buscar Despesas (Resiliência e Cache)
        func getExpenses(month: Int, year: Int) async throws -> [Expense] {
            let calendar = Calendar.current
            
            // 1. FORÇA O SYNC: Sempre que atualizar a tela, tenta mandar os pendentes pro servidor
            Task { try? await syncOfflineExpenses() }
            
            do {
                // 2. Busca na API os dados mais recentes
                let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
                let remoteExpenses = try await networkService.fetchExpenses(month: month, year: year, token: token)
                
                // 3. LIMPEZA DE CACHE (Evita itens duplicados entre o UUID do iPhone e o ID do Java)
                let descriptor = FetchDescriptor<Expense>()
                let allLocal = (try? context.fetch(descriptor)) ?? []
                
                for localExpense in allLocal {
                    // Apaga os locais daquele mês que já estavam sincronizados
                    if localExpense.syncStatus == .synced &&
                       calendar.component(.month, from: localExpense.date) == month &&
                       calendar.component(.year, from: localExpense.date) == year {
                        context.delete(localExpense)
                    }
                }
                
                // 4. Salva os novos dados da API no SwiftData
                for expense in remoteExpenses {
                    context.insert(expense)
                }
                try? context.save()
                
                // 5. A MÁGICA: Pega os que ainda estão PENDENTES no celular e junta com os da API
                let pendingLocal = allLocal.filter {
                    $0.syncStatus == .pending &&
                    calendar.component(.month, from: $0.date) == month &&
                    calendar.component(.year, from: $0.date) == year
                }
                
                // Retorna a lista unificada para o Dashboard
                return (remoteExpenses + pendingLocal).sorted { $0.date > $1.date }
                
            } catch {
                // CAIU A INTERNET? Busca TUDO do banco local!
                print("DEBUG: Falha na rede, buscando dados locais...")
                
                let descriptor = FetchDescriptor<Expense>()
                let allLocal = (try? context.fetch(descriptor)) ?? []
                
                return allLocal.filter {
                    calendar.component(.month, from: $0.date) == month &&
                    calendar.component(.year, from: $0.date) == year
                }.sorted { $0.date > $1.date }
            }
        }
    
    // MARK: - Sincronizador de Pendências
    func syncOfflineExpenses() async throws {
        if isSyncing { return }
        isSyncing = true
        defer { isSyncing = false }
        let descriptor = FetchDescriptor<Expense>()
        let allLocal = (try? context.fetch(descriptor)) ?? []
        let pendingExpenses = allLocal.filter { $0.syncStatus == .pending }
        guard !pendingExpenses.isEmpty else { return }
        let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
        for expense in pendingExpenses {
            do {
                try await networkService.postExpense(expense, token: token)
                expense.syncStatus = .synced
            } catch {
                print("DEBUG: Falha ao sincronizar \(expense.name). Erro: \(error.localizedDescription)")            }
        }
        try? context.save()
    }
    
    // MARK: - Deletar Despesa
    func deleteExpense(_ expense: Expense) async throws {
        let isOnlyLocal = Int(expense.id) == nil
        if !isOnlyLocal {
            let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
            try await networkService.deleteExpense(id: expense.id, token: token)
        }
        context.delete(expense)
        try? context.save()
    }
}
