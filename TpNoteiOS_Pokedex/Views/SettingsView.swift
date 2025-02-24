//
//  SettingsView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isDarkMode: Bool
    @Binding var pokemonLimit: Int
    
    @AppStorage("dailyNotificationHour") private var notificationHour: Int = 9
    @AppStorage("dailyNotificationMinute") private var notificationMinute: Int = 0
    @AppStorage("dailyNotificationsEnabled") private var dailyNotificationsEnabled: Bool = false
    @AppStorage("typeChangeSimulationEnabled") private var typeChangeSimulationEnabled: Bool = false
    
    @State private var showDailyPokemon: Bool = false
    
    private let limitOptions = [151, 251, 386, 493, 649, 721, 809, 898, 1025]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Apparence")) {
                    Toggle("Mode sombre", isOn: $isDarkMode)
                }
                
                Section(header: Text("Données")) {
                    Picker("Nombre de Pokémon", selection: $pokemonLimit) {
                        ForEach(limitOptions, id: \.self) { limit in
                            Text("\(limit) Pokémon").tag(limit)
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Notification quotidienne", isOn: $dailyNotificationsEnabled)
                        .onChange(of: dailyNotificationsEnabled) { newValue in
                            if newValue {
                                NotificationManager.shared.scheduleDailyPokemonReminder(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            } else {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(
                                    withIdentifiers: ["daily-pokemon"]
                                )
                            }
                        }
                    
                    if dailyNotificationsEnabled {
                        HStack {
                            Text("Heure")
                            Spacer()
                            
                            Picker("", selection: $notificationHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: notificationHour) { _ in
                                if dailyNotificationsEnabled {
                                    NotificationManager.shared.scheduleDailyPokemonReminder(
                                        hour: notificationHour,
                                        minute: notificationMinute
                                    )
                                }
                            }
                            
                            Text(":")
                            
                            Picker("", selection: $notificationMinute) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: notificationMinute) { _ in
                                if dailyNotificationsEnabled {
                                    NotificationManager.shared.scheduleDailyPokemonReminder(
                                        hour: notificationHour,
                                        minute: notificationMinute
                                    )
                                }
                            }
                        }
                        
                        Button("Tester notification quotidienne") {
                            NotificationManager.shared.scheduleTestNotification()
                        }
                    }
                    
                    Toggle("Simulations de changement de type", isOn: $typeChangeSimulationEnabled)
                        .onChange(of: typeChangeSimulationEnabled) { newValue in
                            if newValue {
                                NotificationManager.shared.simulateTypeChangesForFavorites(
                                    context: PersistenceController.shared.container.viewContext
                                )
                            }
                        }
                }
                
                Section(header: Text("Pokémon du jour")) {
                    Button("Voir le Pokémon du jour") {
                        showDailyPokemon = true
                    }
                }
                
                Section(header: Text("À propos des limites")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("151 : Génération 1")
                        Text("251 : Génération 2")
                        Text("386 : Génération 3")
                        Text("493 : Génération 4")
                        Text("649 : Génération 5")
                        Text("721 : Génération 6")
                        Text("809 : Génération 7")
                        Text("898 : Génération 8")
                        Text("1025 : Génération 9")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Fermer") {
                    dismiss()
                }
            }
            .sheet(isPresented: $showDailyPokemon) {
                DailyPokemonView()
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            isDarkMode: .constant(false),
            pokemonLimit: .constant(151)
        )
    }
}
