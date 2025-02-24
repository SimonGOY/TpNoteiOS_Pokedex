//
//  PokemonQuizView.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import SwiftUI
import CoreData

struct PokemonQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPokemon: PokemonEntity?
    @State private var options: [String] = []
    @State private var correctAnswer: String = ""
    @State private var selectedAnswer: String?
    @State private var isAnswerRevealed = false
    @State private var score = 0
    @State private var totalQuestions = 0
    @State private var isLoading = true
    @State private var availablePokemons: [PokemonEntity] = []
    @State private var isGameFinished = false
    
    @AppStorage("pokemonLimit") private var pokemonLimit: Int = 151
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Chargement du quiz...")
                } else if isGameFinished {
                    GameFinishedView(score: score, total: totalQuestions)
                } else if let pokemon = currentPokemon {
                    VStack(spacing: 20) {
                        Text("Qui est ce Pokémon ?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ZStack {
                            if let imageURL = pokemon.imageUrl,
                               let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .interpolation(.medium)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 200, height: 200)
                                            .modifier(PokemonQuizImageModifier(
                                                isRevealed: isAnswerRevealed,
                                                colorScheme: colorScheme
                                            ))
                                    case .failure(_):
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 200, height: 200)
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .frame(width: 250, height: 250)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(15)
                        
                        VStack(spacing: 15) {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    selectAnswer(option)
                                }) {
                                    Text(option.capitalizingFirstLetter())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(getButtonColor(for: option))
                                        .cornerRadius(10)
                                }
                                .disabled(isAnswerRevealed)
                            }
                        }
                        .padding()
                        
                        if isAnswerRevealed {
                            HStack {
                                Text("Score: \(score)/\(totalQuestions)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button(action: nextQuestion) {
                                    Text("Suivant")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Qui est ce Pokémon ?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupQuiz()
            }
        }
    }
    
    private func setupQuiz() {
        isLoading = true
        
        // Récupérer tous les Pokémon de la génération
        let fetchRequest: NSFetchRequest<PokemonEntity> = PokemonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id <= %d", pokemonLimit)
        
        do {
            let allPokemons = try viewContext.fetch(fetchRequest)
            
            // Vérifier si tous les Pokémon ont été devinés
            if availablePokemons.isEmpty {
                availablePokemons = allPokemons.shuffled()
            }
            
            // Vérifier si le jeu est terminé
            if availablePokemons.isEmpty || totalQuestions >= allPokemons.count {
                isGameFinished = true
                isLoading = false
                return
            }
            
            // Choisir un Pokémon aléatoire parmi les disponibles
            let randomPokemon = availablePokemons.randomElement()!
            currentPokemon = randomPokemon
            correctAnswer = randomPokemon.name ?? ""
            
            // Supprimer le Pokémon des disponibles
            availablePokemons.removeAll { $0.id == randomPokemon.id }
            
            // Générer 3 pokémon aléatoires supplémentaires pour les options
            var additionalOptions = allPokemons
                .filter { $0.id != randomPokemon.id }
                .shuffled()
                .prefix(3)
                .compactMap { $0.name }
            
            // Mélanger les options
            additionalOptions.append(correctAnswer)
            options = additionalOptions.shuffled()
            
            isAnswerRevealed = false
            selectedAnswer = nil
            totalQuestions += 1
            
            isLoading = false
        } catch {
            print("Erreur lors de la configuration du quiz: \(error)")
            isLoading = false
        }
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        isAnswerRevealed = true
        
        if answer == correctAnswer {
            score += 1
        }
    }
    
    private func nextQuestion() {
        setupQuiz()
    }
    
    private func getButtonColor(for option: String) -> Color {
        guard isAnswerRevealed else {
            return Color.blue
        }
        
        if option == correctAnswer {
            return Color.green
        } else if option == selectedAnswer {
            return Color.red
        }
        
        return Color.blue.opacity(0.5)
    }
}

// Vue pour l'écran de fin de jeu
struct GameFinishedView: View {
    @Environment(\.presentationMode) var presentationMode
    let score: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.yellow)
            
            Text("Félicitations !")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Vous avez terminé le quiz de la génération")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("Score final : \(score)/\(total)")
                .font(.title3)
                .fontWeight(.semibold)
            
            // Évaluation du score
            Text(scoreEvaluation)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            // Bouton pour fermer
            HStack(spacing: 20) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Fermer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .transition(.scale)
    }
    
    private var scoreEvaluation: String {
        let percentage = Double(score) / Double(total) * 100
        
        switch percentage {
        case 90...100:
            return "Incroyable ! Vous êtes un maître Pokémon !"
        case 75..<90:
            return "Excellent ! Vous connaissez très bien les Pokémon."
        case 50..<75:
            return "Bien joué ! Continuez à vous améliorer."
        case 25..<50:
            return "Pas mal. Il y a encore de la marge pour progresser."
        default:
            return "Courage ! Chaque erreur est une opportunité d'apprentissage."
        }
    }
}

// Modificateur personnalisé pour gérer l'apparence de l'image selon que la réponse est révélée et le mode sombre
struct PokemonQuizImageModifier: ViewModifier {
    let isRevealed: Bool
    let colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        if isRevealed {
            // Quand la réponse est révélée, montrer l'image originale
            content
        } else {
            // Quand la réponse n'est pas révélée, utiliser un effet de silhouette
            if colorScheme == .dark {
                content
                    .saturation(0)    // Noir et blanc
                    .contrast(0)      // Réduire le contraste
                    .brightness(10)   // Augmenter la luminosité
                    .opacity(0.5)     // Transparence
                    .colorInvert()    // Inverser les couleurs
            } else {
                content
                    .colorInvert()
                    .colorMultiply(.black)
            }
        }
    }
}

struct PokemonQuizView_Previews: PreviewProvider {
    static var previews: some View {
        PokemonQuizView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
