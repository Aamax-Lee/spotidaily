//
//  SearchResult.swift
//  musictime
//
//  Created by Aamax Lee on 13/5/2024.
//

import Foundation

enum SearchResult {
    case artist(model: ArtistObject)
    case album(model: Album)
    case track(model: TrackObject)
    case playlist(model: PlaylistObject)
}
