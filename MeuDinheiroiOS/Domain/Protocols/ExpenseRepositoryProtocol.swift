//
//  ExpenseRepositoryProtocol.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation

protocol ExpenseRepositoryProtocol {
    func saveExpense(_ expense: Expense) async throws
    func getExpenses(month: Int, year: Int) async throws -> [Expense]
    func deleteExpense(_ expense: Expense) async throws
    func syncOfflineExpenses() async throws
}
