//
//  FirebaseAuthService.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation
import FirebaseAuth

class FirebaseAuthService: AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let firebaseUser = result.user
        return User(id: firebaseUser.uid, email: firebaseUser.email ?? "")
    }
    
    func logout() throws {
        try Auth.auth().signOut()
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        return User(id: firebaseUser.uid, email: firebaseUser.email ?? "")
    }
}
