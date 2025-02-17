//
//  CoreDataManager.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    private let context = PersistenceController.shared.container.viewContext

    func savePokemon(_ pokemon: Pokemon) {
        let entity = PokemonEntity(context: context)
        entity.id = Int64(pokemon.id)
        entity.name = pokemon.name
        entity.imageUrl = pokemon.imageUrl
        entity.types = pokemon.types as NSObject
        entity.stats = pokemon.stats as NSObject

        do {
            try context.save()
            print("✅ Pokémon sauvegardé : \(pokemon.name)")
        } catch {
            print("❌ Erreur de sauvegarde : \(error.localizedDescription)")
        }
    }

    func fetchAllPokemon() -> [PokemonEntity] {
        let request: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Erreur de récupération : \(error.localizedDescription)")
            return []
        }
    }
}
