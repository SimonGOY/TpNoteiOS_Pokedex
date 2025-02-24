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
    @State private var showDetail = false
    @State private var selectedPokemon: PokemonEntity?
    @Environment(\.managedObjectContext) private var viewContext
    
    // Définir les options de tri
    enum SortOption {
        case id, name, favorites
        
        var descriptor: NSSortDescriptor {
            switch self {
            case .id:
                return NSSortDescriptor(keyPath: \PokemonEntity.id, ascending: true)
            case .name:
                return NSSortDescriptor(keyPath: \PokemonEntity.name, ascending: true)
            case .favorites:
                return NSSortDescriptor(keyPath: \PokemonEntity.isFavorite, ascending: false)
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
            case .favorites:
                return p1.id < p2.id  // Si on montre que les favoris, pas besoin de trier par favori
            }
        }
        
        return sorted.filter { pokemon in
            // Filtre de recherche
            let matchesSearch = searchText.isEmpty ||
                (pokemon.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // Filtre de type
            let matchesType: Bool
            if let selectedType = selectedType,
               let pokemonTypes = pokemon.types as? [String] {
                matchesType = pokemonTypes.contains(selectedType)
            } else {
                matchesType = true
            }
            
            // Filtre des favoris
            let matchesFavorites = sortOption == .favorites ? pokemon.isFavorite : true
            
            return matchesSearch && matchesType && matchesFavorites
        }
    }
    
    @State private var isLoading = false
    private let api = PokemonAPI.shared

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    // Picker de tri
                    Picker("Trier par", selection: $sortOption) {
                        Text("ID").tag(SortOption.id)
                        Text("Nom").tag(SortOption.name)
                        Text("Favoris").tag(SortOption.favorites)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Menu pour les types
                    Menu {
                        Button {
                            selectedType = nil
                        } label: {
                            HStack {
                                Text("Tous les types")
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                
                                if selectedType == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        ForEach(availableTypes, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                HStack {
                                    Text(type.capitalizingFirstLetter())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(type.typeColor)
                                        .cornerRadius(10)
                                    
                                    if selectedType == type {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(type.typeColor)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag.fill")
                            Text(selectedType?.capitalizingFirstLetter() ?? "Tous les types")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedType?.typeColor ?? Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                List {
                    ForEach(filteredPokemons, id: \.id) { pokemon in
                        Button {
                            selectedPokemon = pokemon  // Ceci déclenchera la sheet
                        } label: {
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
                                    HStack {
                                        Text("#\(pokemon.id)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        if pokemon.isFavorite {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    
                                    Text(pokemon.name?.capitalizingFirstLetter() ?? "Unknown")
                                        .font(.headline)
                                    
                                    if let types = pokemon.types as? [String] {
                                        HStack {
                                            ForEach(types, id: \.self) { type in
                                                Text(type.capitalizingFirstLetter())
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(type.typeColor)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 8)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .sheet(item: $selectedPokemon) { pokemon in
                    PokemonDetailView(pokemon: pokemon)
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
                        entity.stats = pokemon.stats as NSDictionary
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
