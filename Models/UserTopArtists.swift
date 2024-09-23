//
//  UserTopArtists.swift
//  musictime
//
//  Created by Aamax Lee on 1/5/2024.
//

import Foundation

//response object containing the user's top artists
struct UserTopArtists: Codable {
    let href: String
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
    let items: [ArtistObject]
}

//artist object
struct ArtistObject: Codable {
    let external_urls: ExternalURL
    let followers: Followers
    let genres: [String]
    let href: String
    let id: String
    let images: [Image]
    let name: String
    let popularity: Int
    let type: String
    let uri: String
    
    
}

struct ExternalURL: Codable {
    let spotify: String
}

struct Followers: Codable {
    let href: String? //apparently always set to null -.-
    let total: Int
}

struct Image: Codable {
    let height: Int?
    let url: String
    let width: Int?
}
 
