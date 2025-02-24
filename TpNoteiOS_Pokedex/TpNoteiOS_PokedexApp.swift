//
//  TpNoteiOS_PokedexApp.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import SwiftUI
import UserNotifications

@main
struct TpNoteiOS_PokedexApp: App {
    let persistenceController = PersistenceController.shared
    
    // Configurer le délégué de notification
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // Timer pour simuler les changements de type
    @State private var typeChangeTimer: Timer?
    @AppStorage("typeChangeSimulationEnabled") private var typeChangeSimulationEnabled: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Vérifier s'il faut choisir un nouveau Pokémon quotidien
                    DailyPokemonService.shared.chooseDailyPokemon(
                        context: persistenceController.container.viewContext
                    )
                    
                    // Configurer le timer pour simuler les changements de type
                    if typeChangeSimulationEnabled {
                        setupTypeChangeTimer()
                    }
                }
                .onChange(of: typeChangeSimulationEnabled) { newValue in
                    if newValue {
                        setupTypeChangeTimer()
                    } else {
                        typeChangeTimer?.invalidate()
                        typeChangeTimer = nil
                    }
                }
        }
    }
    
    private func setupTypeChangeTimer() {
        // Invalider l'ancien timer s'il existe
        typeChangeTimer?.invalidate()
        
        // Créer un nouveau timer qui s'exécute toutes les heures
        typeChangeTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            NotificationManager.shared.simulateTypeChangesForFavorites(
                context: persistenceController.container.viewContext
            )
        }
    }
}

// AppDelegate pour gérer les notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configurer le délégué de notification
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        return true
    }
}
