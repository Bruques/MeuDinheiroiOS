//
//  DashboardViewModel.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 13/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var totalMes: Double = 0.0
    
    @Published var mesAtual: Int = Calendar.current.component(.month, from: Date())
    @Published var anoAtual: Int = Calendar.current.component(.year, from: Date())
    
    private let repository: ExpenseRepositoryProtocol
    
    init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }
    
    func carregarGastos() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            expenses = try await repository.getExpenses(month: mesAtual, year: anoAtual)
            calcularTotal()
        } catch {
            print("DEBUG: Erro ao buscar gastos: \(error)")
        }
    }
    
    private func calcularTotal() {
        totalMes = expenses.reduce(0) { $0 + $1.value }
    }
    
    func mudarMes(incremento: Int) async {
        var dateComponents = DateComponents()
        dateComponents.month = incremento
        
        let calendar = Calendar.current
        let dataAtual = calendar.date(from: DateComponents(year: anoAtual, month: mesAtual)) ?? Date()
        
        if let novaData = calendar.date(byAdding: dateComponents, to: dataAtual) {
            mesAtual = calendar.component(.month, from: novaData)
            anoAtual = calendar.component(.year, from: novaData)
            await carregarGastos()
        }
    }
    
    func deletarGasto(_ expense: Expense) async {
        do {
            try await repository.deleteExpense(expense)
            if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses.remove(at: index)
            }
        } catch {
            print("DEBUG: Erro ao deletar gasto: \(error)")
            // Opcional: Você pode colocar uma variável @Published de erro aqui para mostrar um alerta na tela
        }
    }
}

struct CategorySummary: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
}

extension DashboardViewModel {
    var groupedExpenses: [CategorySummary] {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return grouped.map { (category, expenses) in
            CategorySummary(category: category, total: expenses.reduce(0) { $0 + $1.value })
        }
        .sorted { $0.total > $1.total }
    }
}
