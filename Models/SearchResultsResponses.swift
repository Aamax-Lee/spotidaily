//
//  SearchResultsResponses.swift
//  musictime
//
//  Created by Aamax Lee on 13/5/2024.
//

import Foundation

struct SearchResultsResponse: Codable {
    let albums: SearchAlbum
    let artists: SearchArtist
    let playlists: SearchPlaylist
    let tracks: SearchTrack
}

struct SearchAlbum: Codable {
    let items: [Album]
}

struct SearchArtist: Codable {
    let items: [ArtistObject]
}

struct SearchPlaylist: Codable {
    let items: [PlaylistObject]
}

struct SearchTrack: Codable {
    let items: [TrackObject]
}

struct PlaylistObject: Codable {
    let collaborative: Bool
    let description: String?
//    let externalUrls: ExternalUrls
    let id: String
    let images: [ImageObject]
    let name: String
    let owner: PlaylistOwner
    let isPublic: Bool?
    let snapshotId: String?
    let tracks: PlaylistTracks
    let type: String
    let uri: String
}

struct ExternalUrls: Codable {
    let spotify: String
}

struct ImageObject: Codable {
    let url: String
}

struct PlaylistOwner: Codable {
    let id: String
    let display_name: String?
}


struct PlaylistTracks: Codable {
    let href: String
    let total: Int
}


