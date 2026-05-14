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
    @State private var showAddExpense = false
    private let repository: ExpenseRepositoryProtocol
    
    init(repository: ExpenseRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(repository: repository))
        self.repository = repository
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !syncManager.isOnline {
                    offlineWarning
                }
                monthNavigation
                    .padding(.top, 8)
                totalSummary
                    .padding(.bottom, 16)
            }
            .background(Color(.systemBackground))
            ScrollView {
                VStack(spacing: 24) {
                    chartSection
                    expensesList
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
            }
            .task {
                await viewModel.carregarGastos()
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(repository: repository, onSaveSuccess: {
                    Task { await viewModel.carregarGastos() }
                })
            }
            .onChange(of: syncManager.isOnline) { isOnline in
                if isOnline {
                    print("DEBUG: Internet voltou! Recarregando a tela...")
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await viewModel.carregarGastos()
                    }
                }
            }
        }
    }
    
    // Offline warning
    private var offlineWarning: some View {
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
    
    // Month navigation
    private var monthNavigation: some View {
        HStack {
            Button(action: { Task { await viewModel.mudarMes(incremento: -1) } }) {
                Image(systemName: "chevron.left").padding()
            }
            Spacer()
            Text("\(mesNome(viewModel.mesAtual)) \(String(viewModel.anoAtual))")
                .font(.headline)
            Spacer()
            Button(action: { Task { await viewModel.mudarMes(incremento: 1) } }) {
                Image(systemName: "chevron.right").padding()
            }
        }
        .padding(.horizontal)
    }
    
    // Total summary
    private var totalSummary: some View {
        VStack(spacing: 4) {
            Text("Total Gasto")
                .foregroundColor(.secondary)
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(String(format: "R$ %.2f",
                            viewModel.totalMes))
                    .font(.system(size: 36, weight: .bold))
            }
        }
    }
    
    // Chart section
    @ViewBuilder
    private var chartSection: some View {
        if !viewModel.expenses.isEmpty {
            Chart(viewModel.groupedExpenses) { item in
                SectorMark(angle: .value("Valor", item.total),
                           innerRadius: .ratio(0.6),
                           angularInset: 2.0
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Categoria",
                                            item.category))
            }
            .frame(height: 240)
            .chartLegend(position: .top, spacing: 15)
            .padding(.horizontal)
        }
    }
    
    // Expenses list
    private var expensesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.expenses.isEmpty {
                ContentUnavailableView("Sem gastos",
                                       systemImage: "tray",
                                       description: Text("Nenhum gasto encontrado para este período.")
                )
            } else {
                ForEach(viewModel.expenses) { expense in
                    ExpenseRow(expense: expense)
                    Divider()
                        .padding(.leading)
                }
            }
        }
    }
    
    private func mesNome(_ mes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.monthSymbols[mes - 1].capitalized
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
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
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
