//
//  Pokemon.swift
//  TpNoteiOS_Pokedex
//
//  Created by Simon GOY on 2/17/25.
//

import Foundation

struct Pokemon: Identifiable {
    let id: Int
    let name: String
    let imageUrl: String
    let types: [String]
    let stats: [String: Int]
}
