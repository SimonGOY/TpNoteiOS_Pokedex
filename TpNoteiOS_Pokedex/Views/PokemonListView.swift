//
//  PokemonListView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import CoreData
import SwiftUI

struct PokemonListView: View {
    @State private var searchText = ""
    @State private var sortOption = SortOption.id
    @State private var selectedType: String? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    // Définir les options de tri
    enum SortOption {
        case id, name
        
        var descriptor: NSSortDescriptor {
            switch self {
            case .id:
                return NSSortDescriptor(keyPath: \PokemonEntity.id, ascending: true)
            case .name:
                return NSSortDescriptor(keyPath: \PokemonEntity.name, ascending: true)
            }
        }
    }
    
    @FetchRequest private var pokemons: FetchedResults<PokemonEntity>
    
    init() {
        _pokemons = FetchRequest(
            sortDescriptors: [SortOption.id.descriptor],
            animation: .default)
    }
    
    // Obtenir la liste unique des types
    private var availableTypes: [String] {
        let allTypes = pokemons.compactMap { pokemon -> [String]? in
            pokemon.types as? [String]
        }.flatMap { $0 }
        return Array(Set(allTypes)).sorted()
    }
    
    private var filteredPokemons: [PokemonEntity] {
        let sorted = Array(pokemons).sorted { p1, p2 in
                switch sortOption {
                case .id:
                    return p1.id < p2.id
                case .name:
                    return (p1.name ?? "") < (p2.name ?? "")
                }
            }
        
        return sorted.filter { pokemon in
            let matchesSearch = searchText.isEmpty ||
                (pokemon.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesType: Bool
            if let selectedType = selectedType,
               let pokemonTypes = pokemon.types as? [String] {
                matchesType = pokemonTypes.contains(selectedType)
            } else {
                matchesType = true
            }
            
            return matchesSearch && matchesType
        }
    }
    
    @State private var isLoading = false
    private let api = PokemonAPI.shared

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("Trier par", selection: $sortOption) {
                        Text("ID").tag(SortOption.id)
                        Text("Nom").tag(SortOption.name)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Tous").tag(nil as String?)
                        ForEach(availableTypes, id: \.self) { type in
                            Text(type.capitalizingFirstLetter()).tag(type as String?)
                        }
                    }
                }
                .padding()
                
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
                                            .interpolation(.medium)  // Ajout de l'interpolation
                                            .aspectRatio(contentMode: .fit)  // Utilisation de aspectRatio au lieu de scaledToFit
                                            .frame(width: 80, height: 80)  // Dimensions fixes et plus petites
                                            .background(Color.white)  // Ajout d'un fond blanc
                                    case .failure(_):
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                            .background(Color.gray.opacity(0.3))
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 80, height: 80)
                                    @unknown default:
                                        EmptyView()
                                            .frame(width: 80, height: 80)
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.3))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("#\(pokemon.id)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text(pokemon.name?.capitalizingFirstLetter() ?? "Unknown")
                                    .font(.headline)
                                
                                if let types = pokemon.types as? [String] {
                                    Text(types.map { $0.capitalizingFirstLetter() }.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Pokédex")
                .searchable(text: $searchText, prompt: "Chercher Pokémon...")
                .toolbar {
                    Button("Refresh") {
                        Task {
                            await loadPokemons()
                        }
                    }
                }
            }
            .overlay(Group {
                if isLoading {
                    ProgressView()
                }
            })
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
                    let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
                    
                    do {
                        let results = try viewContext.fetch(fetchRequest)
                        let entity: PokemonEntity
                        
                        if let existingPokemon = results.first {
                            entity = existingPokemon
                        } else {
                            entity = PokemonEntity(context: viewContext)
                            entity.id = Int64(pokemon.id)
                        }
                        
                        entity.name = pokemon.name
                        entity.imageUrl = pokemon.imageURL
                        entity.types = pokemon.types as NSArray
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


// Extension pour avoir la première lettre majuscule
extension String {
    func capitalizingFirstLetter() -> String {
        return self.prefix(1).uppercased() + self.dropFirst().lowercased()
    }
}
