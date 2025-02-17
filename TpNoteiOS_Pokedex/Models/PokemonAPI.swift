//
//  PokemonAPI.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import Foundation

class PokemonAPI {
    static let shared = PokemonAPI()
    
    func fetchPokemon(id: Int, completion: @escaping (Pokemon?) -> Void) {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Erreur API : \(error?.localizedDescription ?? "Inconnue")")
                completion(nil)
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(PokemonResponse.self, from: data)
                let pokemon = Pokemon(
                    id: decodedData.id,
                    name: decodedData.name.capitalized,
                    imageUrl: decodedData.sprites.front_default,
                    types: decodedData.types.map { $0.type.name.capitalized },
                    stats: decodedData.stats.reduce(into: [String: Int]()) { result, stat in
                        result[stat.stat.name] = stat.base_stat
                    }
                )
                DispatchQueue.main.async {
                    completion(pokemon)
                }
            } catch {
                print("❌ Erreur de parsing JSON : \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

// MARK: - Structures pour la réponse JSON
struct PokemonResponse: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeEntry]
    let stats: [StatEntry]
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

struct StatEntry: Codable {
    let base_stat: Int
    let stat: StatInfo
}

struct StatInfo: Codable {
    let name: String
}

