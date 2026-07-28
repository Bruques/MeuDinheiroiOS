//
//  NetworkService.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case unauthorized
}

class NetworkService: NetworkServiceProtocol {
    
    private let baseURL = "https://meu-dinheiro-backend-fjdi.onrender.com/api"
    
    // MARK: - Buscar Gastos do Mês (GET)
    func fetchExpenses(month: Int, year: Int, token: String) async throws -> [Expense] {
        guard let url = URL(string: "\(baseURL)/expenses/mes?mes=\(month)&ano=\(year)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw NetworkError.unauthorized
        }
        
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let expenses = try decoder.decode([Expense].self, from: data)
            
            for expense in expenses {
                expense.syncStatus = .synced
            }
            
            return expenses
        } catch {
            print("DEBUG: Erro ao decodificar: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Enviar Gasto (POST)
    func postExpense(_ expense: Expense, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/expenses") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        request.httpBody = try encoder.encode(expense)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - Deletar Gasto (DELETE)
    func deleteExpense(id: String, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/expenses/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - Atualizar Gasto (PUT)
    func updateExpense(_ expense: Expense, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/expenses/\(expense.id)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        request.httpBody = try encoder.encode(expense)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
}
