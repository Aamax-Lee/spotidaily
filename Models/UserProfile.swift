//
//  UserProfile.swift
//  musictime
//
//  Created by Aamax Lee on 29/4/2024.
//

import Foundation
//codable model for user's spotify profile
struct UserProfile: Codable {
    let country: String
    let display_name: String
    let email: String
    let explicit_content: [String: Bool]
    let external_urls: [String: String]
    let id: String
    let product: String
    let images: [UserImage]
}

struct UserImage: Codable {
    let url: String
}

 
