//
//  AddExpenseView.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 13/05/26.
//

import Foundation
import SwiftUI

struct AddExpenseView: View {
    // Usado para fechar essa tela (voltar pro Dashboard)
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddExpenseViewModel
    
    // Função que será executada quando salvar com sucesso (para o Dashboard atualizar os dados)
    var onSaveSuccess: () -> Void
    
    init(repository: ExpenseRepositoryProtocol, onSaveSuccess: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(repository: repository))
        self.onSaveSuccess = onSaveSuccess
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalhes do Gasto")) {
                    TextField("Nome (ex: Mercado)", text: $viewModel.name)
                    
                    TextField("Valor (ex: 150.50)", text: $viewModel.value)
                        .keyboardType(.decimalPad) // Mostra o teclado numérico nativo
                }
                
                Section(header: Text("Classificação")) {
                    Picker("Categoria", selection: $viewModel.category) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Pagamento", selection: $viewModel.paymentType) {
                        ForEach(viewModel.paymentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Data")) {
                    DatePicker("Data do Gasto", selection: $viewModel.date, displayedComponents: .date)
                }
            }
            .navigationTitle("Novo Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botão de Cancelar no topo esquerdo
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                // Botão de Salvar no topo direito
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        Task {
                            let success = await viewModel.salvar()
                            if success {
                                onSaveSuccess() // Avisa o Dashboard pra recarregar
                                dismiss() // Fecha a tela
                            }
                        }
                    }
                    // Desabilita o botão se não tiver nome, valor ou se estiver salvando
                    .disabled(viewModel.name.isEmpty || viewModel.value.isEmpty || viewModel.isSaving)
                }
            }
        }
    }
}
