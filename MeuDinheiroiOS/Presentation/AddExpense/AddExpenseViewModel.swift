//
//  AddExpenseViewModel.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 13/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var value: String = ""
    @Published var category: String = "Alimentação"
    @Published var paymentType: String = "Crédito"
    @Published var date: Date = Date()
    
    @Published var isSaving = false
    
    // Listas pré-definidas para os menus (Pickers)
    let categories = ["Alimentação", "Transporte", "Saúde", "Educação", "Moradia", "Lazer", "Outros"]
    let paymentTypes = ["Crédito", "Débito", "Pix", "Dinheiro"]
    
    private let repository: ExpenseRepositoryProtocol
    
    init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }
    
    // Função para salvar e retornar se deu certo
    func salvar() async -> Bool {
        // Converte o valor digitado (String) para Double, trocando vírgula por ponto se necessário
        let valorFormatado = value.replacingOccurrences(of: ",", with: ".")
        guard let numericValue = Double(valorFormatado) else { return false }
        
        isSaving = true
        defer { isSaving = false }
        
        // Cria a entidade do modelo
        let expense = Expense(
            name: name,
            value: numericValue,
            category: category,
            date: date,
            paymentType: paymentType
        )
        
        do {
            // O repositório faz a mágica de salvar offline e mandar pro Render
            try await repository.saveExpense(expense)
            return true
        } catch {
            print("DEBUG: Erro ao salvar o gasto: \(error)")
            return false
        }
    }
}
