//
//  EditExpenseView.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 15/05/26.
//

import Foundation
import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    private let repository: ExpenseRepositoryProtocol
    
    let expense: Expense
    var onSaveSuccess: () -> Void
    
    @State private var name: String = ""
    @State private var value: Double = 0.0
    @State private var category: String = ""
    @State private var date: Date = Date()
    @State private var paymentType: String = ""
    @State private var isSaving = false
    
    // TODO: - Futuramente pegar essas categorias do backend
    let categorias = ["Alimentação", "Transporte", "Moradia", "Saúde", "Lazer", "Outros"]
    let paymentTypes = ["Crédito", "Débito", "Pix", "Cartão Benefício"]
    
    init(expense: Expense, repository: ExpenseRepositoryProtocol, onSaveSuccess: @escaping () -> Void) {
        self.expense = expense
        self.repository = repository
        self.onSaveSuccess = onSaveSuccess
        
        _name = State(initialValue: expense.name)
        _value = State(initialValue: expense.value)
        _category = State(initialValue: expense.category)
        _date = State(initialValue: expense.date)
        _paymentType = State(initialValue: expense.paymentType)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalhes")) {
                    TextField("Nome", text: $name)
                    
                    TextField("Valor", value: $value, format: .currency(code: "BRL"))
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Classificação")) {
                    Picker("Categoria", selection: $category) {
                        ForEach(categorias, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Pagamento", selection: $paymentType) {
                        ForEach(paymentTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Editar Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        salvarEdicao()
                    }
                    .disabled(name.isEmpty || value <= 0 || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Salvando...")
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func salvarEdicao() {
        isSaving = true
        
        expense.name = name
        expense.value = value
        expense.category = category
        expense.date = date
        expense.paymentType = paymentType
        
        Task {
            do {
                try await repository.updateExpense(expense)
                onSaveSuccess()
                dismiss()
            } catch {
                print("Erro ao atualizar: \(error)")
                isSaving = false
            }
        }
    }
}
