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
    
    // Filtros de tempo padrão (mês e ano atuais)
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
            // Busca no Cérebro (Repositório) que vai decidir se vem da API ou do SwiftData
            expenses = try await repository.getExpenses(month: mesAtual, year: anoAtual)
            calcularTotal()
        } catch {
            print("Erro ao buscar gastos: \(error)")
        }
    }
    
    private func calcularTotal() {
        totalMes = expenses.reduce(0) { $0 + $1.value }
    }
    
    // Método para avançar ou retroceder os meses
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
}
