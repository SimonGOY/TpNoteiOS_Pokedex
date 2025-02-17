//
//  PokemonAPI.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import Foundation

// Structures pour la réponse initiale
struct PokemonListResponse: Codable {
    let results: [PokemonBasicInfo]
}

struct PokemonBasicInfo: Codable {
    let name: String
    let url: String
}

// Structure pour le modèle final
struct PokemonModel: Identifiable, Codable {
    let id: Int
    let name: String
    let imageURL: String?
    let types: [String]
    
    init(id: Int, name: String, imageURL: String?, types: [String]) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.types = types
    }
}

class PokemonAPI {
    static let shared = PokemonAPI()
    
    func fetchPokemons() async throws -> [PokemonModel] {
        // 1. Récupérer la liste basique
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=151")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let basicList = try JSONDecoder().decode(PokemonListResponse.self, from: data)
        
        // 2. Récupérer les détails pour chaque Pokémon
        var detailedPokemons: [PokemonModel] = []
        
        for basicInfo in basicList.results {
            if let detailedPokemon = try? await fetchPokemonDetails(from: basicInfo.url) {
                detailedPokemons.append(detailedPokemon)
            }
        }
        
        return detailedPokemons
    }
    
    private func fetchPokemonDetails(from url: String) async throws -> PokemonModel {
        guard let detailURL = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: detailURL)
        let details = try JSONDecoder().decode(PokemonDetails.self, from: data)
        
        return PokemonModel(
            id: details.id,
            name: details.name,
            imageURL: details.sprites.front_default,
            types: details.types.map { $0.type.name }
        )
    }
}

// Structure pour les détails d'un Pokémon
struct PokemonDetails: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeEntry]
}

struct Sprites: Codable {
    let front_default: String
}

struct TypeEntry: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}
