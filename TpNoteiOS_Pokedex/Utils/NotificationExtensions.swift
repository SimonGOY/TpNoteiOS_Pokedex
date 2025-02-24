//
//  NotificationExtensions.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/24/25.
//

import Foundation

// Extension pour les notifications de combat
extension Notification.Name {
    static let newBattleRequested = Notification.Name("newBattleRequested")
    static let newBattleWithOpponent = Notification.Name("newBattleWithOpponent")
}
