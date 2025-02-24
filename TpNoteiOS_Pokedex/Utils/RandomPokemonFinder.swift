//
//  RandomPokemonFinder.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import Foundation
import CoreData

class RandomPokemonFinder {
    static func getRandomPokemon(excluding pokemonID: Int64, context: NSManagedObjectContext) -> PokemonEntity? {
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        
        // Exclure le Pokémon actuel
        fetchRequest.predicate = NSPredicate(format: "id != %d", pokemonID)
        
        do {
            let pokemons = try context.fetch(fetchRequest)
            guard !pokemons.isEmpty else { return nil }
            
            // Sélectionner un Pokémon aléatoire
            let randomIndex = Int.random(in: 0..<pokemons.count)
            return pokemons[randomIndex]
        } catch {
            print("❌ Erreur lors de la récupération d'un Pokémon aléatoire: \(error.localizedDescription)")
            return nil
        }
    }
}
