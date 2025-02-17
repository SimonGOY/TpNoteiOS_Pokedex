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
    @State private var isFavorite: Bool
    
    init(pokemon: PokemonEntity) {
        self.pokemon = pokemon
        _isFavorite = State(initialValue: pokemon.isFavorite)
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image du Pokémon avec animation
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
                                    .background(Color.white)
                                    .animation(.spring(), value: image)
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
                    
                    // Types
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
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Statistiques")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        StatRow(label: "Numéro", value: Int(pokemon.id))
                        
                        // Vous pouvez ajouter d'autres stats ici quand elles seront disponibles
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationTitle(pokemon.name?.capitalizingFirstLetter() ?? "Détails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
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
        }
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
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
