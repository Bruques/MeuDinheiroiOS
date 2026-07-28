//
//  MockTokenProvider.swift
//  MeuDinheiroiOSTests
//

import Foundation
@testable import MeuDinheiroiOS

struct MockTokenProvider: TokenProviding {
    var tokenToReturn = "fake-token"
    var error: Error?

    func getToken() async throws -> String {
        if let error { throw error }
        return tokenToReturn
    }
}
