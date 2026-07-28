//
//  ExpenseRepositoryTests.swift
//  MeuDinheiroiOSTests
//

import XCTest
import SwiftData
@testable import MeuDinheiroiOS

final class ExpenseRepositoryTests: XCTestCase {

    var context: ModelContext!
    var mockNetwork: MockNetworkService!
    var repository: ExpenseRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let container = try ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        mockNetwork = MockNetworkService()
        // Prevents the fire-and-forget background sync inside getExpenses() from
        // flipping pending expenses to synced mid-test and making assertions flaky.
        mockNetwork.postError = NSError(domain: "test", code: -1)
        repository = ExpenseRepository(networkService: mockNetwork, context: context, tokenProvider: MockTokenProvider())
    }

    override func tearDown() {
        context = nil
        mockNetwork = nil
        repository = nil
        super.tearDown()
    }

    private func makeExpense(id: String = UUID().uuidString, name: String = "Gasto", month: Int = 5, year: Int = 2026, syncStatus: SyncStatus = .pending) -> Expense {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 10
        let date = Calendar.current.date(from: components)!
        return Expense(id: id, name: name, value: 10, category: "Outros", date: date, paymentType: "Débito", syncStatus: syncStatus)
    }

    // MARK: - getExpenses

    func test_getExpenses_success_mergesRemoteWithPendingLocalForSameMonth() async throws {
        let pending = makeExpense(id: "local-1", name: "Pendente", month: 5, year: 2026, syncStatus: .pending)
        context.insert(pending)
        try context.save()

        mockNetwork.expensesToReturn = [makeExpense(id: "42", name: "Remoto", month: 5, year: 2026, syncStatus: .synced)]

        let result = try await repository.getExpenses(month: 5, year: 2026)

        XCTAssertEqual(Set(result.map(\.id)), Set(["local-1", "42"]))
    }

    func test_getExpenses_success_removesStaleSyncedLocalCopiesForThatMonth() async throws {
        let staleSynced = makeExpense(id: "old-remote-copy", month: 5, year: 2026, syncStatus: .synced)
        context.insert(staleSynced)
        try context.save()

        mockNetwork.expensesToReturn = [makeExpense(id: "old-remote-copy-updated", month: 5, year: 2026, syncStatus: .synced)]

        _ = try await repository.getExpenses(month: 5, year: 2026)

        let allLocal = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertFalse(allLocal.contains { $0.id == "old-remote-copy" })
    }

    func test_getExpenses_networkFailure_fallsBackToLocalCache() async throws {
        let local = makeExpense(id: "offline-1", month: 5, year: 2026, syncStatus: .pending)
        context.insert(local)
        try context.save()

        mockNetwork.fetchError = NSError(domain: "test", code: -1)

        let result = try await repository.getExpenses(month: 5, year: 2026)

        XCTAssertEqual(result.map(\.id), ["offline-1"])
    }

    // MARK: - saveExpense

    func test_saveExpense_success_marksExpenseAsSynced() async throws {
        mockNetwork.postError = nil
        let expense = makeExpense(syncStatus: .pending)

        try await repository.saveExpense(expense)

        XCTAssertEqual(expense.syncStatus, .synced)
        XCTAssertEqual(mockNetwork.postedExpenses.map(\.id), [expense.id])
    }

    func test_saveExpense_networkFailure_keepsExpensePendingAndDoesNotThrow() async throws {
        mockNetwork.postError = NSError(domain: "test", code: -1)
        let expense = makeExpense(syncStatus: .pending)

        try await repository.saveExpense(expense)

        XCTAssertEqual(expense.syncStatus, .pending)
        let allLocal = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertTrue(allLocal.contains { $0.id == expense.id })
    }

    // MARK: - deleteExpense

    func test_deleteExpense_withRemoteId_callsNetworkDelete() async throws {
        let expense = makeExpense(id: "123", syncStatus: .synced)
        context.insert(expense)
        try context.save()

        try await repository.deleteExpense(expense)

        XCTAssertEqual(mockNetwork.deletedIds, ["123"])
    }

    func test_deleteExpense_withLocalOnlyId_skipsNetworkCall() async throws {
        let expense = makeExpense(id: UUID().uuidString, syncStatus: .pending)
        context.insert(expense)
        try context.save()

        try await repository.deleteExpense(expense)

        XCTAssertTrue(mockNetwork.deletedIds.isEmpty)
    }

    // MARK: - syncOfflineExpenses

    func test_syncOfflineExpenses_postsPendingExpensesAndMarksThemSynced() async throws {
        mockNetwork.postError = nil
        let pending = makeExpense(id: "pending-1", syncStatus: .pending)
        context.insert(pending)
        try context.save()

        try await repository.syncOfflineExpenses()

        XCTAssertEqual(pending.syncStatus, .synced)
        XCTAssertEqual(mockNetwork.postedExpenses.map(\.id), ["pending-1"])
    }

    func test_syncOfflineExpenses_withNoPendingExpenses_doesNotCallNetwork() async throws {
        let synced = makeExpense(id: "already-synced", syncStatus: .synced)
        context.insert(synced)
        try context.save()

        try await repository.syncOfflineExpenses()

        XCTAssertTrue(mockNetwork.postedExpenses.isEmpty)
    }
}
