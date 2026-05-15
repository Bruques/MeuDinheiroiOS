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
    @Published var selectedCategories: Set<String> = []
    @Published var isLoading = false
    
    @Published var mesAtual: Int = Calendar.current.component(.month, from: Date())
    @Published var anoAtual: Int = Calendar.current.component(.year, from: Date())
    
    var availableCategories: [String] {
        Array(Set(expenses.map { $0.category })).sorted()
    }
    var filteredExpenses: [Expense] {
        if selectedCategories.isEmpty {
            return expenses
        }
        return expenses.filter { selectedCategories.contains($0.category) }
    }
    var totalMes: Double {
        filteredExpenses.reduce(0) { $0 + $1.value }
    }
    
    private let repository: ExpenseRepositoryProtocol
    
    init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }
    
    func carregarGastos() async {
        isLoading = true
        defer { isLoading = false }
        do {
            expenses = try await repository.getExpenses(month: mesAtual, year: anoAtual)
        } catch {
            print("DEBUG: Erro ao buscar gastos: \(error)")
        }
    }
    
    func mudarMes(incremento: Int) async {
        var dateComponents = DateComponents()
        dateComponents.month = incremento
        
        let calendar = Calendar.current
        let dataAtual = calendar.date(from: DateComponents(year: anoAtual, month: mesAtual)) ?? Date()
        
        if let novaData = calendar.date(byAdding: dateComponents, to: dataAtual) {
            mesAtual = calendar.component(.month, from: novaData)
            anoAtual = calendar.component(.year, from: novaData)
            
            clearFilters()
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
        }
    }
    
    // MARK: - Funções de Filtro
    
    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    func clearFilters() {
        selectedCategories.removeAll()
    }
}

// MARK: - Estruturas Auxiliares e Extensões

struct CategorySummary: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
}

extension DashboardViewModel {
    var groupedExpenses: [CategorySummary] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.category }
        return grouped.map { (category, expenses) in
            CategorySummary(category: category, total: expenses.reduce(0) { $0 + $1.value })
        }
        .sorted { $0.total > $1.total }
    }
}
