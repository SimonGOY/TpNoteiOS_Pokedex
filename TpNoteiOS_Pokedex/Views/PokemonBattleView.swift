//
//  PokemonBattleView.swift
//  TpNoteiOS_Pokedex
//
//  Created on 2/24/25.
//

import SwiftUI

struct PokemonBattleView: View {
    let playerPokemon: PokemonEntity
    let opponentPokemon: PokemonEntity
    
    @Environment(\.dismiss) private var dismiss
    @State private var playerHP: Int
    @State private var opponentHP: Int
    @State private var battleLog: [String] = []
    @State private var isBattleOver = false
    @State private var winner: String?
    @State private var isPlayerTurn = true
    @State private var isAttacking = false
    @State private var playerShake = false
    @State private var opponentShake = false
    @State private var showPlayerDamage = false
    @State private var showOpponentDamage = false
    @State private var playerDamage = 0
    @State private var opponentDamage = 0
    @State private var battleStarted = false
    
    init(playerPokemon: PokemonEntity, opponentPokemon: PokemonEntity) {
        self.playerPokemon = playerPokemon
        self.opponentPokemon = opponentPokemon
        
        // Initialiser les points de vie
        _playerHP = State(initialValue: PokemonBattleView.getStatValue(playerPokemon, "hp"))
        _opponentHP = State(initialValue: PokemonBattleView.getStatValue(opponentPokemon, "hp"))
    }
    
    private static func getStatValue(_ pokemon: PokemonEntity, _ statName: String) -> Int {
        if let statsObject = pokemon.stats {
            let statsDict = statsObject as? [String: Any]
            if let value = statsDict?[statName] as? Int {
                return value
            }
            if let value = statsDict?[statName] as? NSNumber {
                return value.intValue
            }
        }
        return 100 // Valeur par défaut
    }
    
    private func getAttackValue(_ pokemon: PokemonEntity) -> Int {
        return PokemonBattleView.getStatValue(pokemon, "attack")
    }
    
    private func getDefenseValue(_ pokemon: PokemonEntity) -> Int {
        return PokemonBattleView.getStatValue(pokemon, "defense")
    }
    
    private func getSpeedValue(_ pokemon: PokemonEntity) -> Int {
        return PokemonBattleView.getStatValue(pokemon, "speed")
    }
    
    private func calculateDamage(attacker: PokemonEntity, defender: PokemonEntity) -> Int {
        let attackValue = getAttackValue(attacker)
        let defenseValue = getDefenseValue(defender)
        
        // Formule simplifiée de dégâts
        let baseDamage = max(5, Int(Double(attackValue) * 0.5 - Double(defenseValue) * 0.25))
        
        // Ajouter un peu d'aléatoire (±20%)
        let randomMultiplier = Double.random(in: 0.8...1.2)
        let finalDamage = Int(Double(baseDamage) * randomMultiplier)
        
        return max(1, finalDamage) // Minimum 1 point de dégâts
    }
    
    private func attack() {
        guard !isBattleOver else { return }
        
        isAttacking = true
        
        if isPlayerTurn {
            // Le joueur attaque
            opponentDamage = calculateDamage(attacker: playerPokemon, defender: opponentPokemon)
            opponentHP = max(0, opponentHP - opponentDamage)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showOpponentDamage = true
                opponentShake = true
            }
            
            battleLog.append("\(playerPokemon.name?.capitalized ?? "Votre Pokémon") attaque et inflige \(opponentDamage) points de dégâts!")
            
            if opponentHP <= 0 {
                endBattle(playerWon: true)
            }
        } else {
            // L'adversaire attaque
            playerDamage = calculateDamage(attacker: opponentPokemon, defender: playerPokemon)
            playerHP = max(0, playerHP - playerDamage)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showPlayerDamage = true
                playerShake = true
            }
            
            battleLog.append("\(opponentPokemon.name?.capitalized ?? "Pokémon adversaire") attaque et inflige \(playerDamage) points de dégâts!")
            
            if playerHP <= 0 {
                endBattle(playerWon: false)
            }
        }
        
        // Réinitialiser les animations après un délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                opponentShake = false
                playerShake = false
                showOpponentDamage = false
                showPlayerDamage = false
            }
            
            if !isBattleOver {
                isPlayerTurn.toggle()
                isAttacking = false
            }
        }
    }
    
    private func determineFirstAttacker() {
        // Le Pokémon avec la vitesse la plus élevée attaque en premier
        let playerSpeed = getSpeedValue(playerPokemon)
        let opponentSpeed = getSpeedValue(opponentPokemon)
        
        if playerSpeed >= opponentSpeed {
            isPlayerTurn = true
            battleLog.append("\(playerPokemon.name?.capitalized ?? "Votre Pokémon") est plus rapide et attaque en premier!")
        } else {
            isPlayerTurn = false
            battleLog.append("\(opponentPokemon.name?.capitalized ?? "Pokémon adversaire") est plus rapide et attaque en premier!")
        }
        
        battleStarted = true
        
        // Démarrer le combat automatiquement après détermination du premier attaquant
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            autoBattle()
        }
    }
    
    // Fonction pour gérer les combats automatiques
    private func autoBattle() {
        if isBattleOver { return }
        
        attack()
        
        // Planifier la prochaine attaque après un délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.isBattleOver {
                self.autoBattle()
            }
        }
    }
    
    private func endBattle(playerWon: Bool) {
        isBattleOver = true
        winner = playerWon ? playerPokemon.name?.capitalized : opponentPokemon.name?.capitalized
        
        if playerWon {
            battleLog.append("\(playerPokemon.name?.capitalized ?? "Votre Pokémon") a gagné le combat!")
        } else {
            battleLog.append("\(opponentPokemon.name?.capitalized ?? "Pokémon adversaire") a gagné le combat!")
        }
    }
    
    var body: some View {
        ZStack {
            // Arrière-plan
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Espace supplémentaire pour éviter la superposition avec le titre de navigation
                Spacer()
                    .frame(height: 50)
                
                // Zone de combat
                HStack(alignment: .top) {
                    // Pokémon de l'adversaire (en haut à droite)
                    VStack {
                        if let imageURL = opponentPokemon.imageUrl,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .interpolation(.medium)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 130)
                                        .overlay(
                                            Text("-\(opponentDamage)")
                                                .font(.headline)
                                                .foregroundColor(.red)
                                                .opacity(showOpponentDamage ? 1 : 0)
                                                .offset(y: showOpponentDamage ? -20 : 0)
                                        )
                                        .offset(x: opponentShake ? -10 : 0)
                                default:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 130)
                                }
                            }
                        }
                        
                        Text(opponentPokemon.name?.capitalized ?? "Adversaire")
                            .font(.headline)
                        
                        // Barre de vie
                        HStack {
                            Text("HP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(opponentHP), total: Double(PokemonBattleView.getStatValue(opponentPokemon, "hp")))
                                .progressViewStyle(LinearProgressViewStyle(tint: PokemonBattleView.healthColor(percentage: Double(opponentHP) / Double(PokemonBattleView.getStatValue(opponentPokemon, "hp")))))
                                .frame(width: 100)
                            
                            Text("\(opponentHP)/\(PokemonBattleView.getStatValue(opponentPokemon, "hp"))")
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.trailing)
                    
                    Spacer()
                }
                
                // Boutons d'action - Déplacé ici pour être plus haut sur l'écran
                HStack(spacing: 20) {
                    if !battleStarted {
                        Button(action: determineFirstAttacker) {
                            Text("Commencer le combat")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    } else if isBattleOver {
                        Button(action: {
                            // Récupérer un nouvel adversaire et relancer un combat
                            let randomPokemon = RandomPokemonFinder.getRandomPokemon(excluding: playerPokemon.id, context: playerPokemon.managedObjectContext!)
                            
                            if let newOpponent = randomPokemon {
                                // Fermer la vue actuelle
                                dismiss()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    // Envoyer notification avec le nouvel adversaire
                                    NotificationCenter.default.post(
                                        name: .newBattleWithOpponent,
                                        object: nil,
                                        userInfo: ["opponent": newOpponent]
                                    )
                                }
                            }
                        }) {
                            Text("Trouver un nouvel adversaire")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        // Combat en cours - ne rien afficher ou afficher un message
                        Text("Combat en cours...")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 5)
                
                // Journal de combat - réduit en hauteur
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(battleLog, id: \.self) { log in
                            Text(log)
                                .font(.subheadline)
                                .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .frame(height: 120)
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Pokémon du joueur (en bas à gauche)
                HStack(alignment: .bottom) {
                    Spacer()
                    
                    VStack {
                        if let imageURL = playerPokemon.imageUrl,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .interpolation(.medium)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 130)
                                        .overlay(
                                            Text("-\(playerDamage)")
                                                .font(.headline)
                                                .foregroundColor(.red)
                                                .opacity(showPlayerDamage ? 1 : 0)
                                                .offset(y: showPlayerDamage ? -20 : 0)
                                        )
                                        .offset(x: playerShake ? 10 : 0)
                                default:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 130)
                                }
                            }
                        }
                        
                        Text(playerPokemon.name?.capitalized ?? "Votre Pokémon")
                            .font(.headline)
                        
                        // Barre de vie
                        HStack {
                            Text("HP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(playerHP), total: Double(PokemonBattleView.getStatValue(playerPokemon, "hp")))
                                .progressViewStyle(LinearProgressViewStyle(tint: PokemonBattleView.healthColor(percentage: Double(playerHP) / Double(PokemonBattleView.getStatValue(playerPokemon, "hp")))))
                                .frame(width: 100)
                            
                            Text("\(playerHP)/\(PokemonBattleView.getStatValue(playerPokemon, "hp"))")
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.leading)
                }
            }
            .padding(.bottom, 20) // Ajouter un peu d'espacement en bas
        }
        .navigationTitle("Combat Pokémon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Abandonner") {
                    dismiss()
                }
            }
        }
        .onAppear {
            battleLog.append("Un combat sauvage commence entre \(playerPokemon.name?.capitalized ?? "votre Pokémon") et \(opponentPokemon.name?.capitalized ?? "Pokémon adversaire")!")
        }
    }
    
    private func healthColor(percentage: Double) -> Color {
        switch percentage {
        case 0.0..<0.2: return .red
        case 0.2..<0.5: return .orange
        default: return .green
        }
    }
    
    // Version statique pour l'utiliser dans le ProgressView
    private static func healthColor(percentage: Double) -> Color {
        switch percentage {
        case 0.0..<0.2: return .red
        case 0.2..<0.5: return .orange
        default: return .green
        }
    }
}
