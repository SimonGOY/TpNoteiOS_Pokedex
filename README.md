# TpNoteiOS_Pokedex - Documentation Technique

## Architecture et Choix Techniques

### Gestion des Données
- **CoreData** utilisé comme solution de persistance
- Structure `PersistenceController` pour gérer le contexte CoreData
- `CoreDataManager` pour les opérations CRUD sur les entités Pokémon

### Récupération des Données
- Utilisation de l'API PokéAPI via `URLSession` et `async/await`
- Classe `PokemonAPI` avec gestion des erreurs et parsing JSON
- Chargement asynchrone des Pokémon avec gestion des limites

### Design Technique
- Architecture MVVM avec séparation claire des responsabilités
- Utilisation extensive de SwiftUI pour l'interface utilisateur
- Animations fluides et réactives

## Fonctionnalités Clés

### Pokédex Dynamique
- Liste des Pokémon avec filtres et tri
- Recherche par nom
- Filtre par type
- Tri par ID, nom, et favoris

### Interactions Utilisateur
- Ajout/Retrait des Pokémon favoris
- Système de combat simulé
- Notifications quotidiennes
- Simulation de changement de type

## Améliorations Techniques

### Gestion des États
- Utilisation de `@State`, `@Binding`, et `@Environment` pour une gestion réactive des états
- `@AppStorage` pour la persistance des préférences utilisateur

### Performance
- Chargement paresseux des données
- Gestion des limites de Pokémon
- Optimisation des requêtes CoreData

### Notifications
- Système de notifications local configurable
- Notification quotidienne du Pokémon
- Simulation de changements de type

## Défis Techniques Résolus

- Synchronisation entre API et CoreData
- Gestion des différentes générations de Pokémon
- Animations complexes dans l'interface utilisateur
- Gestion asynchrone des chargements de données

## Perspectives d'Amélioration

1. Implémentation de tests unitaires
2. Support complet de toutes les générations
3. Système de combat plus complexe
4. Internationalisation de l'application

## Technologies Utilisées

- Swift
- SwiftUI
- CoreData
- URLSession
- UserNotifications
- Async/Await
