//
//  Expense.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation
import SwiftData

enum SyncStatus: String, Codable {
    case synced = "synced"
    case pending = "pending"
}

@Model
final class Expense: Identifiable, Equatable, Codable {
    @Attribute(.unique) var id: String
    var name: String
    var value: Double
    var category: String
    var date: Date
    var paymentType: String
    var syncStatus: SyncStatus
    
    init(id: String = UUID().uuidString, name: String, value: Double, category: String, date: Date = Date(), paymentType: String, syncStatus: SyncStatus = .pending) {
        self.id = id
        self.name = name
        self.value = value
        self.category = category
        self.date = date
        self.paymentType = paymentType
        self.syncStatus = syncStatus
    }

    // --- MÁGICA PARA O CODABLE FUNCIONAR COM CLASSES @MODEL ---
    
    enum CodingKeys: String, CodingKey {
        case id, name, value, category, date, paymentType, syncStatus
    }

    // Necessário para o Decodable (GET)
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(Double.self, forKey: .value)
        category = try container.decode(String.self, forKey: .category)
        date = try container.decode(Date.self, forKey: .date)
        paymentType = try container.decode(String.self, forKey: .paymentType)
        syncStatus = try container.decode(SyncStatus.self, forKey: .syncStatus)
    }

    // Necessário para o Encodable (POST)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(category, forKey: .category)
        try container.encode(date, forKey: .date)
        try container.encode(paymentType, forKey: .paymentType)
        try container.encode(syncStatus, forKey: .syncStatus)
    }
}
