//
//  ContentView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var pokemon: Pokemon?

    var body: some View {
        VStack {
            if let pokemon = pokemon {
                Text("Pokémon : \(pokemon.name)")
                AsyncImage(url: URL(string: pokemon.imageUrl)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                
                Text("Types : \(pokemon.types.joined(separator: ", "))")
                Text("Stats : \(pokemon.stats.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
                
                Button("Sauvegarder") {
                    CoreDataManager.shared.savePokemon(pokemon)
                }
            } else {
                Text("Chargement du Pokémon...")
            }
        }
        .onAppear {
            PokemonAPI.shared.fetchPokemon(id: 1) { fetchedPokemon in
                if let fetchedPokemon = fetchedPokemon {
                    self.pokemon = fetchedPokemon
                }
            }
        }
    }
}


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
