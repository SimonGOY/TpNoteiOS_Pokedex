//
//  DailyPokemonService.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import Foundation
import CoreData
import SwiftUI

class DailyPokemonService: ObservableObject {
    static let shared = DailyPokemonService()
    
    @Published var dailyPokemon: PokemonEntity?
    @AppStorage("lastDailyPokemonDate") private var lastDailyPokemonDate: Double = 0
    
    private init() {}
    
    // Vérifier si un nouveau Pokémon quotidien doit être choisi
    func shouldChooseNewDailyPokemon() -> Bool {
        let lastDate = Date(timeIntervalSince1970: lastDailyPokemonDate)
        return !Calendar.current.isDateInToday(lastDate)
    }
    
    // Choisir un Pokémon aléatoire du jour
    func chooseDailyPokemon(context: NSManagedObjectContext) {
        // Vérifier si nous devons choisir un nouveau Pokémon
        if !shouldChooseNewDailyPokemon() && dailyPokemon != nil {
            return
        }
        
        // Fetcher tous les Pokémon
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        
        do {
            let allPokemons = try context.fetch(fetchRequest)
            guard !allPokemons.isEmpty else { return }
            
            // Choisir un Pokémon aléatoire
            let randomIndex = Int.random(in: 0..<allPokemons.count)
            dailyPokemon = allPokemons[randomIndex]
            
            // Mettre à jour la date du dernier choix
            lastDailyPokemonDate = Date().timeIntervalSince1970
        } catch {
            print("❌ Erreur lors du choix du Pokémon quotidien: \(error.localizedDescription)")
        }
    }
    
    // Récupérer le Pokémon quotidien, en choisir un nouveau si nécessaire
    func getDailyPokemon(context: NSManagedObjectContext) -> PokemonEntity? {
        if shouldChooseNewDailyPokemon() || dailyPokemon == nil {
            chooseDailyPokemon(context: context)
        }
        return dailyPokemon
    }
}
