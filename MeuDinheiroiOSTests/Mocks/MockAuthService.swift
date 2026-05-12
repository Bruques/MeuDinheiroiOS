//
//  MockAuthService.swift
//  MeuDinheiroiOSTests
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation

class MockAuthService: AuthServiceProtocol {
    var shouldReturnError = false
    var userToReturn = User(id: "123", email: "teste@teste.com")
    
    func login(email: String, password: String) async throws -> User {
        if shouldReturnError {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Credenciais inválidas"])
        }
        return userToReturn
    }
    
    func logout() throws { }
    
    func getCurrentUser() -> User? {
        return nil
    }
}
