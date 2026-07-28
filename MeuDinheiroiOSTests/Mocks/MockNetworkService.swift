//
//  MockNetworkService.swift
//  MeuDinheiroiOSTests
//

import Foundation
@testable import MeuDinheiroiOS

class MockNetworkService: NetworkServiceProtocol {
    var expensesToReturn: [Expense] = []
    var fetchError: Error?
    var postError: Error?
    var deleteError: Error?
    var updateError: Error?

    private(set) var postedExpenses: [Expense] = []
    private(set) var deletedIds: [String] = []
    private(set) var updatedExpenses: [Expense] = []

    func fetchExpenses(month: Int, year: Int, token: String) async throws -> [Expense] {
        if let fetchError { throw fetchError }
        return expensesToReturn
    }

    func postExpense(_ expense: Expense, token: String) async throws {
        if let postError { throw postError }
        postedExpenses.append(expense)
    }

    func deleteExpense(id: String, token: String) async throws {
        if let deleteError { throw deleteError }
        deletedIds.append(id)
    }

    func updateExpense(_ expense: Expense, token: String) async throws {
        if let updateError { throw updateError }
        updatedExpenses.append(expense)
    }
}
