//
//  TokenProviding.swift
//  MeuDinheiroiOS
//

import Foundation
import FirebaseAuth

protocol TokenProviding {
    func getToken() async throws -> String
}

struct FirebaseTokenProvider: TokenProviding {
    func getToken() async throws -> String {
        try await Auth.auth().currentUser?.getIDToken() ?? ""
    }
}
