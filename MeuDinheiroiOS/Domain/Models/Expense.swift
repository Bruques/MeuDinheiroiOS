//
//  Expense.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation

enum SyncStatus: String, Codable {
    case synced = "synced"
    case pending = "pending"
}

struct Expense: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var value: Double
    var category: String
    var date: Date
    var paymentType: String
    var syncStatus: SyncStatus

    init(id: String = UUID().uuidString,
         name: String,
         value: Double,
         category: String,
         date: Date = Date(),
         paymentType: String,
         syncStatus: SyncStatus = .pending) {
        self.id = id
        self.name = name
        self.value = value
        self.category = category
        self.date = date
        self.paymentType = paymentType
        self.syncStatus = syncStatus
    }
}
