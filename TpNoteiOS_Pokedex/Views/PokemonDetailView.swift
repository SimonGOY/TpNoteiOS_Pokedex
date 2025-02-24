//
//  PokemonDetailView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import SwiftUI

struct PokemonDetailView: View {
    let pokemon: PokemonEntity
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Binding private var isFavorite: Bool
    @State private var isEnlarged = false
    @State private var appearAnimation = false
    @State private var rotationAngle = 360.0
    @State private var slideAnimation = false
    @State private var isLeaving = false
    @State private var showBattle = false
    @State private var opponentPokemon: PokemonEntity?
    @State private var isFindingOpponent = false
    
    init(pokemon: PokemonEntity, isFavorite: Binding<Bool>) {
        self.pokemon = pokemon
        self._isFavorite = isFavorite
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        pokemon.isFavorite = isFavorite
        
        do {
            try viewContext.save()
        } catch {
            print("Erreur lors de la sauvegarde du favori: \(error)")
        }
    }
    
    private func getStatValue(_ statName: String) -> Int {
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
    
    private func getTypeGradient() -> LinearGradient {
        guard let types = pokemon.types as? [String] else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        let colors = types.map { $0.typeColor.opacity(0.6) } // Ajout d'une opacité
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func findRandomOpponent() {
        isFindingOpponent = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let randomPokemon = RandomPokemonFinder.getRandomPokemon(excluding: pokemon.id, context: viewContext) {
                self.opponentPokemon = randomPokemon
                self.showBattle = true
            } else {
                print("Aucun Pokémon adversaire trouvé")
            }
            
            isFindingOpponent = false
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let imageURL = pokemon.imageUrl,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .interpolation(.medium)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: isEnlarged ? 300 : 200)
                                    .scaleEffect(isEnlarged ? 1.2 : 1)
                                    .rotationEffect(.degrees(appearAnimation ? 0 : 360))
                                    .offset(x: !slideAnimation ? UIScreen.main.bounds.width :
                                              isLeaving ? -UIScreen.main.bounds.width : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.6), value: appearAnimation)
                                    .animation(.easeInOut(duration: 0.7), value: slideAnimation)
                                    .animation(.easeInOut(duration: 0.5), value: isLeaving)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            isEnlarged.toggle()
                                        }
                                    }
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
                    
                    // Types with animation
                    if let types = pokemon.types as? [String] {
                        HStack {
                            ForEach(types, id: \.self) { type in
                                Text(type.capitalizingFirstLetter())
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(type.typeColor)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.top)
                        .opacity(slideAnimation ? 1 : 0)
                        .offset(y: slideAnimation ? 0 : 50)
                    }
                    
                    // Bouton de combat
                    Button(action: findRandomOpponent) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.white)
                            
                            Text(isFindingOpponent ? "Recherche d'un adversaire..." : "Lancer un combat")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.horizontal)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .opacity(slideAnimation ? 1 : 0)
                        .offset(y: slideAnimation ? 0 : 50)
                    }
                    .disabled(isFindingOpponent)
                    .padding(.horizontal)
                    
                    // Stats with animation
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Statistiques")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        StatRow(label: "Numéro pokédex", value: Int(pokemon.id))
                        Group {
                            StatBarRow(label: "HP", value: getStatValue("hp"), maxValue: 255)
                            StatBarRow(label: "Attaque", value: getStatValue("attack"), maxValue: 255)
                            StatBarRow(label: "Défense", value: getStatValue("defense"), maxValue: 255)
                            StatBarRow(label: "Attaque Spéciale", value: getStatValue("special-attack"), maxValue: 255)
                            StatBarRow(label: "Défense Spéciale", value: getStatValue("special-defense"), maxValue: 255)
                            StatBarRow(label: "Vitesse", value: getStatValue("speed"), maxValue: 255)
                        }
                        .opacity(slideAnimation ? 1 : 0)
                        .offset(y: slideAnimation ? 0 : 50)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                }
                .padding()
            }
            .background(getTypeGradient())
            .navigationTitle(pokemon.name?.capitalizingFirstLetter() ?? "Détails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLeaving = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .gray)
                    }
                }
            }
            .onAppear {
                // Déclencher les animations avec un léger délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        appearAnimation = true
                    }
                    withAnimation(.easeInOut(duration: 0.7)) {
                        slideAnimation = true
                    }
                }
                
                // Observer les notifications pour les nouveaux combats
                NotificationCenter.default.addObserver(forName: .newBattleRequested, object: nil, queue: .main) { _ in
                    findRandomOpponent()
                }
                
                NotificationCenter.default.addObserver(forName: .newBattleWithOpponent, object: nil, queue: .main) { notification in
                    if let userInfo = notification.userInfo,
                       let opponent = userInfo["opponent"] as? PokemonEntity {
                        self.opponentPokemon = opponent
                        self.showBattle = true
                    } else {
                        findRandomOpponent()
                    }
                }
            }
            .fullScreenCover(isPresented: $showBattle) {
                if let opponent = opponentPokemon {
                    NavigationView {
                        PokemonBattleView(playerPokemon: pokemon, opponentPokemon: opponent)
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.black.opacity(0.7)) // Au lieu de .secondary
            Spacer()
            Text("\(value)")
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
        .padding(.vertical, 4)
    }
}

struct StatBarRow: View {
    let label: String
    let value: Int
    let maxValue: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(value)")
                    .fontWeight(.bold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 20)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 20)
                        .foregroundColor(statColor(value: value))
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
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

extension String {
    var typeColor: Color {
        switch self.lowercased() {
        case "bug": return Color(red: 0.4, green: 0.7, blue: 0.1)
        case "dark": return Color(red: 0.2, green: 0.2, blue: 0.2)
        case "dragon": return Color(red: 0.1, green: 0.6, blue: 0.7)
        case "electric": return Color(red: 1.0, green: 0.9, blue: 0.1)
        case "fairy": return Color(red: 0.9, green: 0.3, blue: 0.6)
        case "fighting": return Color(red: 0.8, green: 0.3, blue: 0.1)
        case "fire": return Color(red: 0.9, green: 0.2, blue: 0.2)
        case "flying": return Color(red: 0.5, green: 0.6, blue: 0.8)
        case "ghost": return Color(red: 0.4, green: 0.3, blue: 0.6)
        case "grass": return Color(red: 0.3, green: 0.7, blue: 0.3)
        case "ground": return Color(red: 0.7, green: 0.5, blue: 0.3)
        case "ice": return Color(red: 0.5, green: 0.8, blue: 0.9)
        case "normal": return Color(red: 0.7, green: 0.7, blue: 0.7)
        case "poison": return Color(red: 0.6, green: 0.2, blue: 0.6)
        case "psychic": return Color(red: 0.9, green: 0.3, blue: 0.5)
        case "rock": return Color(red: 0.7, green: 0.6, blue: 0.3)
        case "steel": return Color(red: 0.6, green: 0.6, blue: 0.7)
        case "water": return Color(red: 0.3, green: 0.5, blue: 0.9)
        default: return Color.gray
        }
    }
}
