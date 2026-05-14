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
    
    let categories = ["Alimentação", "Transporte", "Saúde", "Educação", "Moradia", "Lazer", "Outros"]
    let paymentTypes = ["Crédito", "Débito", "Pix", "Dinheiro"]
    
    private let repository: ExpenseRepositoryProtocol
    
    init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }
    
    func salvar() async -> Bool {
        let valorFormatado = value.replacingOccurrences(of: ",", with: ".")
        guard let numericValue = Double(valorFormatado) else { return false }
        
        isSaving = true
        defer { isSaving = false }
        
        let expense = Expense(
            name: name,
            value: numericValue,
            category: category,
            date: date,
            paymentType: paymentType
        )
        
        do {
            try await repository.saveExpense(expense)
            return true
        } catch {
            print("DEBUG: Erro ao salvar o gasto: \(error)")
            return false
        }
    }
}
