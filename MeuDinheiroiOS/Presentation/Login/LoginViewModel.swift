//
//  LoginViewModel.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func login() async {
        errorMessage = nil
        
        if email.isEmpty || password.isEmpty {
            errorMessage = "Preencha todos os campos."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _ = try await authService.login(email: email, password: password)
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
