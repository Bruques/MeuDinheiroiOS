//
//  AuthServiceProtocol.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() throws
    func getCurrentUser() -> User?
}
