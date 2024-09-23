//
//  AuthResponse.swift
//  musictime
//
//  Created by Aamax Lee on 25/4/2024.
//

import Foundation
//codable model for the response we get after exchanging the authorization code for a token
struct AuthResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
    let token_type: String
}
 
