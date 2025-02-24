//
//  ContentView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showDailyPokemon: Bool = false
    @State private var showSelectedPokemon: Bool = false
    @State private var selectedPokemon: PokemonEntity?
    
    var body: some View {
        PokemonListView()
            .overlay(
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showDailyPokemon = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Pokémon du jour")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                    }
                    .padding(.bottom, 30)
                }
            )
            .sheet(isPresented: $showDailyPokemon) {
                DailyPokemonView()
            }
            .sheet(item: $selectedPokemon) { pokemon in
                PokemonDetailView(
                    pokemon: pokemon,
                    isFavorite: Binding(
                        get: { pokemon.isFavorite },
                        set: { newValue in
                            pokemon.isFavorite = newValue
                            try? PersistenceController.shared.container.viewContext.save()
                        }
                    )
                )
            }
            .onAppear {
                // Observer les notifications pour afficher le Pokémon du jour
                setupNotificationObservers()
            }
    }
    
    private func setupNotificationObservers() {
        // Observer la notification pour afficher le Pokémon du jour
        NotificationCenter.default.addObserver(
            forName: NotificationDelegate.showDailyPokemonNotification,
            object: nil,
            queue: .main
        ) { _ in
            showDailyPokemon = true
        }
        
        // Observer la notification pour afficher un Pokémon spécifique
        NotificationCenter.default.addObserver(
            forName: NotificationDelegate.showPokemonDetailNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let pokemon = userInfo["pokemon"] as? PokemonEntity {
                selectedPokemon = pokemon
                showSelectedPokemon = true
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
