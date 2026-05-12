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
            print("Salvo apenas offline. Motivo: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Buscar Despesas (Resiliência)
    func getExpenses(month: Int, year: Int) async throws -> [Expense] {
        do {
            // 1. Tenta pegar os dados mais atualizados do backend
            let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
            let remoteExpenses = try await networkService.fetchExpenses(month: month, year: year, token: token)
            
            // 2. Salva no banco local para o usuário ter na próxima vez que abrir sem internet
            for expense in remoteExpenses {
                context.insert(expense)
                // O SwiftData substitui o antigo pelo novo automaticamente por causa do @Attribute(.unique) do ID
            }
            try? context.save()
            
            return remoteExpenses
            
        } catch {
            // 3. CAIU A INTERNET OU DEU ERRO 500? Busca do banco local!
            print("Falha na rede, buscando dados locais...")
            
            let descriptor = FetchDescriptor<Expense>()
            let allLocal = (try? context.fetch(descriptor)) ?? []
            
            // Filtra os gastos do mês/ano específico
            let calendar = Calendar.current
            return allLocal.filter {
                calendar.component(.month, from: $0.date) == month &&
                calendar.component(.year, from: $0.date) == year
            }
        }
    }
    
    // MARK: - Sincronizador de Pendências
    func syncOfflineExpenses() async throws {
        // 1. Puxa tudo do banco local
        let descriptor = FetchDescriptor<Expense>()
        let allLocal = (try? context.fetch(descriptor)) ?? []
        
        // 2. Filtra só os que estão pendentes de envio
        let pendingExpenses = allLocal.filter { $0.syncStatus == .pending }
        
        // Se não tiver nada, encerra cedo
        guard !pendingExpenses.isEmpty else { return }
        
        let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
        
        // 3. Tenta enviar um por um
        for expense in pendingExpenses {
            do {
                try await networkService.postExpense(expense, token: token)
                expense.syncStatus = .synced // Maravilha, subiu!
            } catch {
                print("Ainda sem conexão para o gasto: \(expense.name)")
            }
        }
        
        // Salva os novos status no banco
        try? context.save()
    }
}
