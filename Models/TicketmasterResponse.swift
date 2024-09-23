//
//  TicketmasterResponse.swift
//  musictime
//
//  Created by Aamax Lee on 21/5/2024.
//

import Foundation

// MARK: - TicketmasterResponse
struct TicketmasterResponse: Codable {
//    let _links: Links
    let _embedded: Embedded
    let page: Page
}

struct Page: Codable {
    let size: Int
    let totalElements: Int
    let totalPages: Int
    
    let number: Int
}

// MARK: - Embedded
struct Embedded: Codable {
    let events: [Event]
}

// MARK: - Event
struct Event: Codable {
    let name: String
    let type: String
    let id: String
    let url: String
    let dates: Dates
    let images: [EventImage]
//    let classifications: [Classification]
//    let venues: [Venue]
}

// MARK: - Classification
struct Classification: Codable {
    let primary: Bool
    let segment, genre, subGenre: Segment
}

// MARK: - Segment
struct Segment: Codable {
    let id, name: String
}

// MARK: - Dates
struct Dates: Codable {
    let start: Start
    let timezone: String
    let status: Status
}

// MARK: - Start
struct Start: Codable {
    let localDate: String
//    let dateTBD, dateTBA, timeTBA, noSpecificTime: Bool
}

// MARK: - Status
struct Status: Codable {
    let code: String
}

// MARK: - Image
struct EventImage: Codable {
//    let ratio, url: String?
    let url: String
    let width, height: Int
    let fallback: Bool
}

// MARK: - Venue
struct Venue: Codable {
    let name, type, id: String
    let locale, postalCode, timezone: String
    let city: City
    let state: State
    let country: Country
    let address: Address
    let location: Location
    let markets: [Market]
    let links: Links
}

// MARK: - Address
struct Address: Codable {
    let line1: String
}

// MARK: - City
struct City: Codable {
    let name: String
}

// MARK: - Country
struct Country: Codable {
    let name, countryCode: String
}

// MARK: - Location
struct Location: Codable {
    let longitude, latitude: String
}

// MARK: - Market
struct Market: Codable {
    let id: String
}

// MARK: - State
struct State: Codable {
    let name, stateCode: String
}

// MARK: - Links
struct Links: Codable {
    let `self`, next: Next?
}

// MARK: - Next
struct Next: Codable {
    let href: String
    let templated: Bool
}
