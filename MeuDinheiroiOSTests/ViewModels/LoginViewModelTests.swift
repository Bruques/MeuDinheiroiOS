//
//  LoginViewModelTests.swift
//  MeuDinheiroiOSTests
//
//  Created by Bruno Marques on 11/05/26.
//

import XCTest
@testable import MeuDinheiroiOS

@MainActor
final class LoginViewModelTests: XCTestCase {
    
    var viewModel: LoginViewModel!
    var mockAuthService: MockAuthService!
    
    // Roda ANTES de cada teste
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = LoginViewModel(authService: mockAuthService)
    }
    
    // Roda DEPOIS de cada teste
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // TODO: - Deixar tudo em EN
    func test_login_comCamposVazios_deveMostrarMensagemDeErro() async {
        // 1. Preparação (Arrange)
        viewModel.email = ""
        viewModel.password = ""
        
        // 2. Ação (Act)
        await viewModel.login()
        
        // 3. Verificação (Assert)
        XCTAssertEqual(viewModel.errorMessage, "Preencha todos os campos.")
    }
    
    func test_login_comCredenciaisValidas_deveAutenticarComSucesso() async {
        // 1. Preparação
        viewModel.email = "bruno@teste.com"
        viewModel.password = "123456"
        mockAuthService.shouldReturnError = false
        
        // 2. Ação
        await viewModel.login()
        
        // 3. Verificação
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.errorMessage)
    }
}
