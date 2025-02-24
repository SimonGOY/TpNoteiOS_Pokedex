//
//  CoreDataManager.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import CoreData

extension NSArray {
    @objc(_bridgeToObjectiveC)
    public func _bridgeToObjectiveC() -> NSArray {
        return self
    }
}

class CoreDataManager {
    static let shared = CoreDataManager()
    private let context = PersistenceController.shared.container.viewContext

    // Accès public au context (en lecture seule)
    func getContext() -> NSManagedObjectContext {
        return context
    }
    
    // Sauvegarde un tableau de Pokémon dans CoreData
    func savePokemon(_ pokemons: [Pokemon], context: NSManagedObjectContext) {
        for pokemon in pokemons {
            // Vérification si le Pokémon existe déjà dans CoreData
            let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", pokemon.id)
            
            do {
                let existingPokemons = try context.fetch(fetchRequest)
                
                if existingPokemons.isEmpty {
                    // Si le Pokémon n'existe pas, on l'ajoute
                    createPokemonEntity(from: pokemon, context: context)
                } else if let existingPokemon = existingPokemons.first {
                    // Si le Pokémon existe déjà, on le met à jour
                    updatePokemonEntity(existingPokemon, with: pokemon)
                }
            } catch {
                print("❌ Erreur de vérification du Pokémon (ID: \(pokemon.id)): \(error.localizedDescription)")
            }
        }
        saveContext(context) // Appel à la méthode de sauvegarde du contexte
    }
    
    // Méthode pour créer un Pokémon dans CoreData
    private func createPokemonEntity(from pokemon: Pokemon, context: NSManagedObjectContext) {
        let entity = PokemonEntity(context: context)
        entity.id = Int64(pokemon.id)
        entity.name = pokemon.name
        entity.imageUrl = pokemon.imageUrl
        entity.types = pokemon.types as NSArray
        
        // Conversion directe des stats en NSDictionary
        let statsDict = NSDictionary(dictionary: pokemon.stats)
        entity.stats = statsDict
        print("Saving stats for \(pokemon.name): \(statsDict)")
    }

    
    // Méthode pour mettre à jour un Pokémon existant dans CoreData
    private func updatePokemonEntity(_ existingPokemon: PokemonEntity, with pokemon: Pokemon) {
        existingPokemon.name = pokemon.name
        existingPokemon.imageUrl = pokemon.imageUrl
        existingPokemon.types = pokemon.types as NSArray
        
        // Conversion directe des stats en NSDictionary
        let statsDict = NSDictionary(dictionary: pokemon.stats)
        existingPokemon.stats = statsDict
        print("Updating stats for \(pokemon.name): \(statsDict)")
    }
    
    // Sauvegarde le contexte CoreData et gère les erreurs
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save() // Tente de sauvegarder les changements dans le contexte
                print("✅ Sauvegarde réussie !")
            } catch {
                // Capture l'erreur et affiche un message
                print("❌ Erreur de sauvegarde : \(error.localizedDescription)")
            }
        }
    }
}
