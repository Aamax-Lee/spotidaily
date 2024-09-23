//
//  UserTopTracks.swift
//  musictime
//
//  Created by Aamax Lee on 6/5/2024.
//

import Foundation

//response object containing the user's top songs
struct UserTopTracks: Codable {
    let href: String
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
    let items: [TrackObject]
}

struct TrackObject: Codable {
    let album: Album
    let artists: [TracksArtistObject]
    let disc_number: Int
    let duration_ms: Int
    let explicit: Bool
    let external_ids: ExternalID
    let external_urls: ExternalURL
    let href: String
    let id: String
    let is_local: Bool
    let name: String
    let popularity: Int
    let preview_url: String?
    let track_number: Int
    let type: String
    let uri: String
}

struct TracksArtistObject: Codable {
//    let external_urls: ExternalURL
//    let followers: Followers
//    let genres: [String]
//    let href: String
//    let id: String
//    let images: [Image]
    let name: String
//    let popularity: Int
//    let type: String
//    let uri: String
}

struct Album: Codable {
    let album_type: String
//    let artists: [ArtistObject]
    let external_urls: ExternalURL
    let href: String
    let id: String
    let images: [Image]
    let name: String
    let release_date: String
    let release_date_precision: String
    let total_tracks: Int
    let type: String
    let uri: String
}

struct ExternalID: Codable {
    let isrc: String
}
