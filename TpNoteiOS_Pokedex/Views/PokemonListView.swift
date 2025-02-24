//
//  PokemonListView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import CoreData
import SwiftUI

struct PokemonListView: View {
    // MARK: - Properties
    @State private var searchText = ""
    @State private var sortOption = SortOption.id
    @State private var selectedType: String? = nil
    @State private var showDetail = false
    @State private var selectedPokemon: PokemonEntity?
    @State private var previousSortOption = SortOption.id
    @State private var animateList = false
    @State private var filterMenuOffset: CGFloat = 0
    @State private var isLoading = false
    @State private var cardScale: CGFloat = 0.8
    @State private var isFilterVisible = false
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("pokemonLimit") private var pokemonLimit: Int = 151
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var showSettings = false
    
    private let api = PokemonAPI.shared
    
    // MARK: - Enum
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
    
    // MARK: - FetchRequest
    @FetchRequest private var pokemons: FetchedResults<PokemonEntity>
    
    init() {
        _pokemons = FetchRequest(
            sortDescriptors: [SortOption.id.descriptor],
            predicate: NSPredicate(format: "id <= %d", 151),  // Limite par défaut
            animation: .default)
    }
    
    // MARK: - Computed Properties
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
                return p1.id < p2.id
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
            
            let matchesFavorites = sortOption == .favorites ? pokemon.isFavorite : true
            
            return matchesSearch && matchesType && matchesFavorites
        }
    }
    
    // MARK: - Private Methods
    private func loadPokemons() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let pokemonsFromAPI = try await api.fetchPokemons(limit: pokemonLimit)
            
            await viewContext.perform {
                // Supprimer les Pokémon au-delà de la nouvelle limite
                let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id > %d", pokemonLimit)
                
                do {
                    let pokemonsToDelete = try viewContext.fetch(fetchRequest)
                    for pokemon in pokemonsToDelete {
                        viewContext.delete(pokemon)
                    }
                } catch {
                    print("Erreur lors de la suppression des Pokémon en surplus : \(error)")
                }
                
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
                        
                        // Ne pas écraser les favoris existants
                        if entity.name != pokemon.name || entity.imageUrl == nil {
                            entity.name = pokemon.name
                            entity.imageUrl = pokemon.imageURL
                            entity.types = pokemon.types as NSArray
                            entity.stats = pokemon.stats as NSDictionary
                        }
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
    
    var body: some View {
            NavigationView {
                VStack {
                    filterSection
                    pokemonList
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .navigationTitle("Pokédex")
                .toolbar {
                    toolbarContent
                }
                .onChange(of: pokemonLimit) { _ in
                    // Mettre à jour la FetchRequest
                    let predicate = NSPredicate(format: "id <= %d", pokemonLimit)
                    pokemons.nsPredicate = predicate
                    
                    // Recharger les données depuis l'API
                    Task {
                        await loadPokemons()
                    }
                }
                .sheet(item: $selectedPokemon) { pokemon in
                    PokemonDetailView(
                        pokemon: pokemon,
                        isFavorite: Binding(
                            get: { pokemon.isFavorite },
                            set: { newValue in
                                pokemon.isFavorite = newValue
                                try? viewContext.save()
                            }
                        )
                    )
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(
                        isDarkMode: $isDarkMode,
                        pokemonLimit: $pokemonLimit
                    )
                }
                .overlay(loadingOverlay)
                .onAppear {
                    // Réinitialiser le badge de notification lors de l'ouverture de l'app
                    NotificationManager.shared.resetBadge()
                    
                    // Vérifier et charger les Pokémon si nécessaire
                    Task {
                        if pokemons.isEmpty {
                            await loadPokemons()
                        }
                    }
                }
            }
        }
        
    private var filterSection: some View {
            VStack {
                HStack {
                    Picker("Trier par", selection: $sortOption.animation()) {
                        Text("ID").tag(SortOption.id)
                        Text("Nom").tag(SortOption.name)
                        Text("Favoris").tag(SortOption.favorites)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .transition(.move(edge: .top))
                    
                    typeFilterMenu
                }
                .padding()
                .background(isDarkMode ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 5)
                .padding(.horizontal)
                .offset(y: filterMenuOffset)
                .onAppear {
                    withAnimation(.spring()) {
                        filterMenuOffset = 0
                        isFilterVisible = true
                    }
                }
            }
        }
        
        private var typeFilterMenu: some View {
            Menu {
                Button {
                    withAnimation(.spring()) {
                        selectedType = nil
                    }
                } label: {
                    HStack {
                        Text("Tous les types")
                            .foregroundColor(.primary)
                        if selectedType == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(availableTypes, id: \.self) { type in
                    Button {
                        withAnimation(.spring()) {
                            selectedType = type
                        }
                    } label: {
                        HStack {
                            Text(type.capitalizingFirstLetter())
                                .foregroundColor(.white)
                            if selectedType == type {
                                Image(systemName: "checkmark")
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
                .scaleEffect(cardScale)
                .onAppear {
                    withAnimation(.spring()) {
                        cardScale = 1.0
                    }
                }
            }
        }
        
        private var pokemonList: some View {
            List {
                ForEach(filteredPokemons, id: \.id) { pokemon in
                    Button {
                        selectedPokemon = pokemon
                    } label: {
                        PokemonRow(pokemon: pokemon)
                            .opacity(animateList ? 1 : 0)
                            .offset(x: animateList ? 0 : -50)
                            .animation(.spring().delay(Double(filteredPokemons.firstIndex(of: pokemon) ?? 0) * 0.05),
                                     value: animateList)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .searchable(text: $searchText.animation(), prompt: "Chercher Pokémon...")
            .onChange(of: sortOption) { _ in
                animationToggle()
            }
            .onChange(of: selectedType) { _ in
                animationToggle()
            }
            .onAppear {
                withAnimation(.spring().delay(0.3)) {
                    animateList = true
                }
            }
        }
        
        private var toolbarContent: some ToolbarContent {
            Group {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        
                        Button("Refresh") {
                            Task {
                                await loadPokemons()
                            }
                        }
                    }
                }
            }
        }
        
        private var loadingOverlay: some View {
            Group {
                if isLoading {
                    ProgressView()
                }
            }
        }
        
        private func animationToggle() {
            withAnimation(.spring()) {
                animateList = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring()) {
                        animateList = true
                    }
                }
            }
        }
}

// MARK: - PokemonRow
struct PokemonRow: View {
    let pokemon: PokemonEntity
    @State private var isPressed = false
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isFavorite: Bool
    
    init(pokemon: PokemonEntity) {
        self.pokemon = pokemon
        // Initialiser l'état avec la valeur actuelle
        _isFavorite = State(initialValue: pokemon.isFavorite)
    }
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: pokemon.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .interpolation(.medium)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                case .failure(_):
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                @unknown default:
                    EmptyView()
                        .frame(width: 80, height: 80)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("#\(pokemon.id)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .rotationEffect(.degrees(isPressed ? 360 : 0))
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
                                .scaleEffect(isPressed ? 1.05 : 1.0)
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
        .onLongPressGesture {
            withAnimation(.spring()) {
                isPressed.toggle()
            }
        }
        .onChange(of: pokemon.isFavorite) { newValue in
            isFavorite = newValue
        }
    }
}

// MARK: - String Extension
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst().lowercased()
    }
}
