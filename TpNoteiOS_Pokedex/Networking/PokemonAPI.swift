//
//  PokemonAPI.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import Foundation

class PokemonAPI {
    static let shared = PokemonAPI()

    // Fonction pour récupérer tous les Pokémon
    func fetchPokemons() async throws -> [PokemonModel] {
        // URL pour récupérer la liste des Pokémon (nom + URL)
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let pokemonResponse = try JSONDecoder().decode(PokemonListResponse.self, from: data)
        
        // Récupérer les détails pour chaque Pokémon dans la liste
        var pokemonsWithDetails: [PokemonModel] = []
        
        // Parcours de chaque Pokémon pour récupérer ses détails
        for pokemon in pokemonResponse.results {
            do {
                let detailedPokemon = try await fetchPokemonDetails(for: pokemon)
                pokemonsWithDetails.append(detailedPokemon)
            } catch {
                print("Error fetching details for \(pokemon.name): \(error)")
            }
        }
        
        return pokemonsWithDetails
    }

    // Fonction pour récupérer les détails d'un Pokémon
    func fetchPokemonDetails(for pokemon: PokemonModel) async throws -> PokemonModel {
        var updatedPokemon = pokemon
        let url = URL(string: pokemon.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(PokemonDetails.self, from: data)
        
        // Mise à jour de l'image
        updatedPokemon.imageURL = decoded.sprites.front_default
        
        // Mise à jour des types (si présents)
        updatedPokemon.types = decoded.types?.map { $0.type.name } ?? []

        return updatedPokemon
    }
}

// MARK: - Structures pour la réponse JSON

// Structure pour récupérer la liste des Pokémon (nom + URL)
struct PokemonListResponse: Codable {
    let results: [PokemonModel] // Cela fait référence à la structure PokemonModel
}

// Structure pour récupérer les détails d'un Pokémon (image, types, statistiques, etc.)
struct PokemonDetails: Codable {
    let sprites: Sprites
    let types: [TypeEntry]?
    let stats: [StatEntry]
}

// Structure pour l'image d'un Pokémon
struct Sprites: Codable {
    let front_default: String
}

// Structure pour les types d'un Pokémon
struct TypeEntry: Codable {
    let type: TypeInfo
}

// Structure contenant l'information du type (nom du type)
struct TypeInfo: Codable {
    let name: String
}

// Structure pour les statistiques de base d'un Pokémon
struct StatEntry: Codable {
    let base_stat: Int
    let stat: StatInfo
}

// Structure contenant l'information sur le nom d'une statistique (ex. "hp", "attack")
struct StatInfo: Codable {
    let name: String
}

// Structure pour chaque Pokémon de la liste
struct PokemonModel: Identifiable, Codable {
    var id: Int? {
        // Extraction de l'ID depuis l'URL
        guard let idString = url.split(separator: "/").last,
              let id = Int(idString) else {
            return nil
        }
        return id
    }
    var name: String
    var url: String
    var imageURL: String?
    var types: [String] = []
}

extension Pokemon {
    init(from model: PokemonModel) {
        self.id = model.id ?? 0
        self.name = model.name
        self.imageUrl = model.imageURL ?? ""  // Utiliser "" si l'image est nil
        self.types = model.types
        self.stats = [:] // Placeholder pour les stats, tu peux les mettre à jour plus tard
    }
}
