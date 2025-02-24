//
//  NotificationDelegate.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import Foundation
import UserNotifications
import SwiftUI
import CoreData

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let viewContext = PersistenceController.shared.container.viewContext
    
    // Notification pour ouvrir le Pokémon du jour
    static let showDailyPokemonNotification = Notification.Name("showDailyPokemon")
    
    // Notification pour afficher un Pokémon spécifique
    static let showPokemonDetailNotification = Notification.Name("showPokemonDetail")
    
    // Gérer la notification reçue lorsque l'application est au premier plan
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Afficher la notification même si l'application est au premier plan
        completionHandler([.banner, .sound, .badge])
    }
    
    // Gérer la notification lorsque l'utilisateur tape dessus
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        // Gérer les différents types de notifications
        if identifier == "daily-pokemon" {
            // Choisir un nouveau Pokémon quotidien
            DailyPokemonService.shared.chooseDailyPokemon(context: viewContext)
            
            // Poster une notification pour ouvrir la vue du Pokémon du jour
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.showDailyPokemonNotification, object: nil)
            }
        } else if identifier.starts(with: "type-change-") {
            // Extraire l'ID du Pokémon de l'identifiant de notification
            let components = identifier.split(separator: "-")
            if components.count >= 3, let pokemonID = Int64(components[2]) {
                // Charger le Pokémon correspondant
                let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", pokemonID)
                
                do {
                    let results = try viewContext.fetch(fetchRequest)
                    if let pokemon = results.first {
                        // Poster une notification pour afficher ce Pokémon dans l'application
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: Self.showPokemonDetailNotification,
                                object: nil,
                                userInfo: ["pokemon": pokemon]
                            )
                        }
                        print("👆 L'utilisateur a ouvert la notification pour le Pokémon ID: \(pokemonID)")
                    }
                } catch {
                    print("❌ Erreur lors de la récupération du Pokémon: \(error.localizedDescription)")
                }
            }
        }
        
        // Réinitialiser le badge
        NotificationManager.shared.resetBadge()
        
        completionHandler()
    }
}
