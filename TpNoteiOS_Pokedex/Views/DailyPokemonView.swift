//
//  DailyPokemonView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

//
//  DailyPokemonView.swift
//  TpNoteiOS_Pokedex
//
//  Created on 2/24/25.
//

import SwiftUI

struct DailyPokemonView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var dailyPokemon: PokemonEntity?
    @State private var isLoading = true
    @State private var showSettings = false
    @AppStorage("dailyNotificationHour") private var notificationHour: Int = 9
    @AppStorage("dailyNotificationMinute") private var notificationMinute: Int = 0
    @AppStorage("dailyNotificationsEnabled") private var notificationsEnabled: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond basé sur le type du Pokémon
                if let pokemon = dailyPokemon, let types = pokemon.types as? [String], !types.isEmpty {
                    getTypeGradient(types: types)
                        .ignoresSafeArea()
                } else {
                    // Fond par défaut si pas de Pokémon ou de type
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                VStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else if let pokemon = dailyPokemon {
                        VStack(spacing: 20) {
                            Text("Pokémon du jour")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top, 40) // Plus d'espace en haut
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            
                            Spacer(minLength: 20) // Espace supplémentaire entre le titre et l'image
                            
                            if let imageURL = pokemon.imageUrl,
                               let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .interpolation(.medium)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 200)
                                            .background(
                                                Circle()
                                                    .fill(Color.white.opacity(0.8))
                                                    .frame(width: 220, height: 220)
                                            )
                                    case .failure(_):
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 200)
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            
                            Text(pokemon.name?.capitalized ?? "Inconnu")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                                .padding(.vertical)
                            
                            // Types
                            if let types = pokemon.types as? [String] {
                                HStack(spacing: 15) {
                                    ForEach(types, id: \.self) { type in
                                        Text(type.capitalized)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(type.typeColor)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            
                            // Statistiques avec fond plus opaque et contrasté
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Statistiques")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black) // Texte en noir pour plus de contraste
                                    .padding(.bottom, 5)
                                
                                Group {
                                    // Version modifiée de StatBarRow pour une meilleure lisibilité
                                    DailyStatBarRow(label: "HP", value: getStatValue(pokemon, "hp"), maxValue: 255)
                                    DailyStatBarRow(label: "Attaque", value: getStatValue(pokemon, "attack"), maxValue: 255)
                                    DailyStatBarRow(label: "Défense", value: getStatValue(pokemon, "defense"), maxValue: 255)
                                    DailyStatBarRow(label: "Vitesse", value: getStatValue(pokemon, "speed"), maxValue: 255)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.9)) // Fond plus opaque
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            Button(action: {
                                // Afficher les détails complets du Pokémon
                                navigateToPokemonDetails(pokemon)
                            }) {
                                Text("Voir les détails complets")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom)
                        }
                        .padding()
                    } else {
                        Text("Aucun Pokémon du jour disponible")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Pokémon du jour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "bell")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NotificationSettingsView(
                    hour: $notificationHour,
                    minute: $notificationMinute,
                    isEnabled: $notificationsEnabled
                )
            }
        }
        .onAppear {
            loadDailyPokemon()
        }
    }
    
    private func loadDailyPokemon() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dailyPokemon = DailyPokemonService.shared.getDailyPokemon(context: viewContext)
            isLoading = false
        }
    }
    
    private func getStatValue(_ pokemon: PokemonEntity, _ statName: String) -> Int {
        if let statsObject = pokemon.stats {
            let statsDict = statsObject as? [String: Any]
            if let value = statsDict?[statName] as? Int {
                return value
            }
            if let value = statsDict?[statName] as? NSNumber {
                return value.intValue
            }
        }
        return 0
    }
    
    private func getTypeGradient(types: [String]) -> LinearGradient {
        let colors = types.map { $0.typeColor.opacity(0.7) }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func navigateToPokemonDetails(_ pokemon: PokemonEntity) {
        // Ici, vous pourriez naviguer vers la vue détaillée du Pokémon
        // Mais cela nécessite une approche différente de navigation
        // Pour l'instant, nous fermons simplement cette vue
        presentationMode.wrappedValue.dismiss()
    }
}

// Version modifiée de StatBarRow avec un meilleur contraste
struct DailyStatBarRow: View {
    let label: String
    let value: Int
    let maxValue: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .foregroundColor(.black) // Texte noir pour un meilleur contraste
                    .fontWeight(.medium)
                Spacer()
                Text("\(value)")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 20)
                        .opacity(0.2) // Fond de barre plus subtil
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 20)
                        .foregroundColor(statColor(value: value))
                        .cornerRadius(10)
                }
            }
            .frame(height: 20)
        }
        .padding(.vertical, 4)
    }
    
    private func statColor(value: Int) -> Color {
        let percentage = Double(value) / Double(maxValue)
        switch percentage {
        case 0.0..<0.2: return .red
        case 0.2..<0.4: return .orange
        case 0.4..<0.7: return .yellow
        case 0.7..<0.9: return .green
        default: return .blue
        }
    }
}

struct NotificationSettingsView: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @Binding var isEnabled: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications quotidiennes")) {
                    Toggle("Activer les notifications", isOn: $isEnabled)
                        .onChange(of: isEnabled) { value in
                            if value {
                                scheduleNotification()
                            } else {
                                cancelNotification()
                            }
                        }
                }
                
                if isEnabled {
                    Section(header: Text("Heure de notification")) {
                        HStack {
                            Picker("Heure", selection: $hour) {
                                ForEach(hours, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                            
                            Text(":")
                                .font(.title)
                                .padding(.horizontal, 5)
                            
                            Picker("Minute", selection: $minute) {
                                ForEach(minutes, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                        }
                        .onChange(of: hour) { _ in scheduleNotification() }
                        .onChange(of: minute) { _ in scheduleNotification() }
                    }
                    
                    Section {
                        Button("Tester la notification") {
                            NotificationManager.shared.scheduleTestNotification()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Réglages de notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func scheduleNotification() {
        NotificationManager.shared.scheduleDailyPokemonReminder(hour: hour, minute: minute)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-pokemon"])
    }
}
