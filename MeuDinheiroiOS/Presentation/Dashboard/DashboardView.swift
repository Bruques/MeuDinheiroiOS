//
//  DashboardView.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 13/05/26.
//

import Foundation
import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject var syncManager: SyncManager
    
    init(repository: ExpenseRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 🔴 AVISO DE MODO OFFLINE (Só aparece se a internet cair)
                if !syncManager.isOnline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Modo Offline - Sincronizando quando conectar")
                    }
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                }
                
                // 📅 NAVEGAÇÃO DE MESES
                HStack {
                    Button(action: { Task { await viewModel.mudarMes(incremento: -1) } }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text("\(mesNome(viewModel.mesAtual)) \(viewModel.anoAtual)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { Task { await viewModel.mudarMes(incremento: 1) } }) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                // 💰 RESUMO TOTAL
                VStack(spacing: 4) {
                    Text("Total Gasto")
                        .foregroundColor(.secondary)
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text(String(format: "R$ %.2f", viewModel.totalMes))
                            .font(.system(size: 36, weight: .bold))
                    }
                }
                .padding(.vertical)
                
                // 📊 GRÁFICO DE CATEGORIAS
                if !viewModel.expenses.isEmpty {
                    Chart {
                        ForEach(viewModel.expenses) { expense in
                            BarMark(
                                x: .value("Categoria", expense.category),
                                y: .value("Valor", expense.value)
                            )
                            .foregroundStyle(by: .value("Categoria", expense.category))
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
                
                // 📋 LISTA DE GASTOS
                List(viewModel.expenses) { expense in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.name)
                                .font(.headline)
                            Text(expense.category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "R$ %.2f", expense.value))
                                .fontWeight(.bold)
                            
                            // Ícone de reloginho para itens que não subiram pro servidor ainda
                            if expense.syncStatus == .pending {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                            } else {
                                Image(systemName: "checkmark.icloud.fill")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Dashboard")
            // Carrega os dados assim que a tela aparece
            .task {
                await viewModel.carregarGastos()
            }
        }
    }
    
    // Função auxiliar para converter o número do mês em nome
    private func mesNome(_ mes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.monthSymbols[mes - 1].capitalized
    }
}
