//
//  TickemasterAuthenticationManager.swift
//  musictime
//
//  Created by Aamax Lee on 21/5/2024.
//

import Foundation


final class TicketmasterAuthManager {
    static let shared = TicketmasterAuthManager()
    
    private let apiKey = "YOUR_TICKETMASTER_API_KEY"
    
    private init() {}
    
    public var apiKeyParameter: String {
        return "apikey=\(apiKey)"
    }
}
