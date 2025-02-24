//
//  NotificationManager.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    // Demander l'autorisation pour envoyer des notifications
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Autorisation de notification accordée")
            } else if let error = error {
                print("❌ Erreur d'autorisation de notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Programmer une notification quotidienne pour découvrir un Pokémon aléatoire
    func scheduleDailyPokemonReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        
        // Supprimer les notifications existantes avec le même identifiant
        center.removePendingNotificationRequests(withIdentifiers: ["daily-pokemon"])
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "Découverte Pokémon du jour"
        content.body = "Ouvrez l'application pour découvrir un nouveau Pokémon aujourd'hui !"
        content.sound = .default
        content.badge = 1
        
        // Configurer le déclencheur pour l'heure spécifiée chaque jour
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Créer la requête de notification
        let request = UNNotificationRequest(
            identifier: "daily-pokemon",
            content: content,
            trigger: trigger
        )
        
        // Ajouter la requête au centre de notification
        center.add(request) { error in
            if let error = error {
                print("❌ Erreur de programmation de notification quotidienne: \(error.localizedDescription)")
            } else {
                print("✅ Notification quotidienne programmée pour \(hour):\(minute)")
            }
        }
    }
    
    // Programmer une notification immédiate pour un test
    func scheduleTestNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "Test de notification"
        content.body = "Ceci est un test de notification locale."
        content.sound = .default
        
        // Configurer le déclencheur pour 5 secondes plus tard
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Créer la requête de notification
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )
        
        // Ajouter la requête au centre de notification
        center.add(request) { error in
            if let error = error {
                print("❌ Erreur de programmation de notification de test: \(error.localizedDescription)")
            } else {
                print("✅ Notification de test programmée pour 5 secondes plus tard")
            }
        }
    }
    
    // Envoyer une notification immédiate pour un changement de type de Pokémon
    func notifyPokemonTypeChange(pokemon: PokemonEntity, oldType: String, newType: String) {
        let center = UNUserNotificationCenter.current()
        
        let pokemonName = pokemon.name?.capitalized ?? "Inconnu"
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "Changement de type pour \(pokemonName)"
        content.body = "\(pokemonName) a changé de type \(oldType.capitalized) à \(newType.capitalized) !"
        content.sound = .default
        content.badge = 1
        
        // Créer la requête de notification avec un déclencheur immédiat
        let request = UNNotificationRequest(
            identifier: "type-change-\(pokemon.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        // Ajouter la requête au centre de notification
        center.add(request) { error in
            if let error = error {
                print("❌ Erreur d'envoi de notification de changement de type: \(error.localizedDescription)")
            } else {
                print("✅ Notification de changement de type envoyée pour \(pokemonName)")
            }
        }
    }
    
    // Simuler un changement de type pour les Pokémon favoris
    func simulateTypeChangesForFavorites(context: NSManagedObjectContext) {
        // Récupérer tous les Pokémon favoris
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == YES")
        
        do {
            let favoritePokemons = try context.fetch(fetchRequest)
            
            for pokemon in favoritePokemons {
                // Vérifier si le Pokémon a des types
                if let types = pokemon.types as? [String], !types.isEmpty {
                    // Choisir un type aléatoire à remplacer
                    let randomIndex = Int.random(in: 0..<types.count)
                    let oldType = types[randomIndex]
                    
                    // Générer un nouveau type aléatoire différent de l'ancien
                    let possibleTypes = [
                        "normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison",
                        "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"
                    ]
                    
                    var newTypes = types
                    var newType: String
                    
                    repeat {
                        newType = possibleTypes.randomElement() ?? "normal"
                    } while newType == oldType
                    
                    // Remplacer l'ancien type par le nouveau
                    newTypes[randomIndex] = newType
                    
                    // Mettre à jour les types du Pokémon
                    pokemon.types = newTypes as NSArray
                    
                    // Envoyer une notification
                    notifyPokemonTypeChange(pokemon: pokemon, oldType: oldType, newType: newType)
                }
            }
            
            // Sauvegarder les changements
            try context.save()
            
        } catch {
            print("❌ Erreur lors de la simulation des changements de type: \(error.localizedDescription)")
        }
    }
    
    // Réinitialiser le badge de l'application
    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ Erreur lors de la réinitialisation du badge: \(error.localizedDescription)")
            }
        }
    }
}
