//
//  PokemonAPI.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import Foundation

// MARK: - Response Structures
struct PokemonListResponse: Codable {
    let results: [PokemonBasicInfo]
}

struct PokemonBasicInfo: Codable {
    let name: String
    let url: String
}

// MARK: - Detail Structures
struct PokemonDetails: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeEntry]
    let stats: [Stat]
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

struct Stat: Codable {
    let base_stat: Int
    let stat: StatInfo
}

struct StatInfo: Codable {
    let name: String
}

// MARK: - Model Structure
struct PokemonModel: Identifiable, Codable {
    let id: Int
    let name: String
    let imageURL: String?
    let types: [String]
    let stats: [String: Int]
    
    init(id: Int, name: String, imageURL: String?, types: [String], stats: [String: Int]) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.types = types
        self.stats = stats
    }
}

// MARK: - API Class
class PokemonAPI {
    static let shared = PokemonAPI()
    
    func fetchPokemons() async throws -> [PokemonModel] {
        // 1. Récupérer la liste basique
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=1025")!
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
        
        // Créer un dictionnaire des stats avec les bons noms
        var statsDict: [String: Int] = [:]
        for stat in details.stats {
            // Convertir les noms des stats pour correspondre à ceux que nous utilisons
            let statName = stat.stat.name
            statsDict[statName] = stat.base_stat
        }
        
        // Pour déboguer
        print("Stats for Pokemon \(details.name): \(statsDict)")
        
        return PokemonModel(
            id: details.id,
            name: details.name,
            imageURL: details.sprites.front_default,
            types: details.types.map { $0.type.name },
            stats: statsDict
        )
    }
}
