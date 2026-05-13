//
//  LoginView.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 11/05/26.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    private let repository: ExpenseRepositoryProtocol
    
    init(authService: AuthServiceProtocol,
         repository: ExpenseRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
        self.repository = repository
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("MeuDinheiro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Acesse sua conta para continuar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
                
                VStack(spacing: 16) {
                    TextField("E-mail", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    SecureField("Senha", text: $viewModel.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    Task {
                        await viewModel.login()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Entrar")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            .padding()

            .navigationDestination(isPresented: $viewModel.isAuthenticated) {
                DashboardView(repository: repository)
                    .navigationBarBackButtonHidden()
            }
        }
    }
}

// TODO: - Arrumar o preview
//#Preview {
//    LoginView(authService: MockAuthService())
//}
