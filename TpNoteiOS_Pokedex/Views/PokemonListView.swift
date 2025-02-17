//
//  PokemonListView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import CoreData
import SwiftUI

struct PokemonListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
        
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PokemonEntity.name, ascending: true)]
    ) private var pokemons: FetchedResults<PokemonEntity>
    
    // Filtrer les Pokémon en fonction du texte de recherche
    private var filteredPokemons: [PokemonEntity] {
        if searchText.isEmpty {
            return Array(pokemons)
        } else {
            return pokemons.filter { pokemon in
                pokemon.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    @State private var isLoading = false
    private let api = PokemonAPI.shared

    var body: some View {
        NavigationView {
                    VStack {
                        // Ajouter la barre de recherche
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        List {
                            ForEach(filteredPokemons, id: \.id) { pokemon in
                                HStack {
                                    if let imageURL = pokemon.imageUrl,
                                       let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 100, height: 100)
                                            case .failure(_):
                                                Image(systemName: "photo")
                                                    .frame(width: 100, height: 100)
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(pokemon.name ?? "Unknown")
                                            .font(.headline)
                                        if let types = pokemon.types as? String {
                                            Text(types)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .navigationTitle("Pokédex")
                        .toolbar {
                            Button("Refresh") {
                                Task {
                                    await loadPokemons()
                                }
                            }
                        }
                        .overlay(Group {
                            if isLoading {
                                ProgressView()
                            }
                        })
                    }
                    .onAppear {
                        if pokemons.isEmpty {
                            Task {
                                await loadPokemons()
                            }
                        }
                    }
                }
    }

    private func loadPokemons() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let pokemonsFromAPI = try await api.fetchPokemons()
            
            await viewContext.perform {
                for pokemon in pokemonsFromAPI {
                    // Chercher si le Pokémon existe déjà
                    let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
                    
                    do {
                        let results = try viewContext.fetch(fetchRequest)
                        let entity: PokemonEntity
                        
                        if let existingPokemon = results.first {
                            // Mettre à jour le Pokémon existant
                            entity = existingPokemon
                        } else {
                            // Créer un nouveau Pokémon
                            entity = PokemonEntity(context: viewContext)
                            entity.id = Int64(pokemon.id)
                        }
                        
                        // Mettre à jour les données
                        entity.name = pokemon.name
                        entity.imageUrl = pokemon.imageURL
                        entity.types = pokemon.types.joined(separator: ", ") as NSString
                    } catch {
                        print("Error updating pokemon \(pokemon.id): \(error)")
                    }
                }
                
                try? viewContext.save()
            }
        } catch {
            print("Error loading pokemons: \(error)")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search Pokémon...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
