//
//  NetworkServiceProtocol.swift
//  MeuDinheiroiOS
//

import Foundation

protocol NetworkServiceProtocol {
    func fetchExpenses(month: Int, year: Int, token: String) async throws -> [Expense]
    func postExpense(_ expense: Expense, token: String) async throws
    func deleteExpense(id: String, token: String) async throws
    func updateExpense(_ expense: Expense, token: String) async throws
}
