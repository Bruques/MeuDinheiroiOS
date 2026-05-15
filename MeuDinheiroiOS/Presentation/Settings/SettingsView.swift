//
//  SettingsView.swift
//  MeuDinheiroiOS
//
//  Created by Bruno Marques on 14/05/26.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Conta")) {
                    Text(Auth.auth().currentUser?.email ?? "Usuário")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sair do App")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Sobre")) {
                    Text("Meu Dinheiro v1.0")
                        .font(.caption)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pronto") { dismiss() }
                }
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Erro ao deslogar: \(error.localizedDescription)")
        }
    }
}
