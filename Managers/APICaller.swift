//
//  APICaller.swift
//  musictime
//
//  Created by Aamax Lee on 29/4/2024.
//

import Foundation

//class to make API calls to Spotify
final class APICaller {
    static let shared = APICaller()
    
    private init() {}
    
//    start of url for all api calls to spotify
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum APIError: Error {
        case failedToGetData
    }
    
//    Retrieves the current user's profile
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
//        Create a request for getting the user's profile
        createRequest(with: URL(string: Constants.baseAPIURL + "/me"),
                      type: .GET
        ) { baseRequest in
//            Perform the data task with the created request
            let task = URLSession.shared.dataTask(with: baseRequest) {
                data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
//                Decode the received data into a UserProfile object
                do {
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    completion(.success(result))
                }
                catch {
                    print(error.localizedDescription)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
//    Retrieves the current user's top artists
    public func getUserTopArtists(completion: @escaping (Result<UserTopArtists, Error>) -> Void) {
            createRequest(with: URL(string: Constants.baseAPIURL + "/me/top/artists?limit=5"),
                          type: .GET
            ) { baseRequest in
//                Perform the data task with the created request
                let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                    guard let data = data, error == nil else {
//                        print("Straight up failed")
                        completion(.failure(APIError.failedToGetData))
                        return
                    }
                    
//                    Decode the received data into a UserTopArtists object
                    do {
                        let result = try JSONDecoder().decode(UserTopArtists.self, from: data)
                        completion(.success(result))
                    } catch {
                        completion(.failure(error))
                    }
                }
                task.resume()
            }
        }
    
//    Retrieves the current user's top tracks
    public func getUserTopTracks(completion: @escaping (Result<UserTopTracks, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/top/tracks?limit=5"),
                      type: .GET
        ) { baseRequest in
//            Perform the data task with the created request
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
//                Decode the received data into a UserTopTracks object
                do {

                    let result = try JSONDecoder().decode(UserTopTracks.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
//    searches for items on Spotify using the provided query
    public func search(with query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/search?limit=10&type=album,artist,playlist,track&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
                      type: .GET
        ) { baseRequest in
            print(baseRequest.url?.absoluteString ?? "none")
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(SearchResultsResponse.self, from: data)
                    var searchResults: [SearchResult] = []
                    
                    searchResults.append(contentsOf: result.tracks.items.compactMap({ .track(model: $0)
                    }))
//                    below for future implementation
//                    searchResults.append(contentsOf: result.albums.items.compactMap({ .album(model: $0)
//                    }))
//                    searchResults.append(contentsOf: result.playlists.items.compactMap({ .playlist(model: $0)
//                    }))
//                    searchResults.append(contentsOf: result.artists.items.compactMap({ .artist(model: $0)
//                    }))
                    
                    completion(.success(searchResults))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    
//   http method for api calls
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    // Creates a URLRequest with the provided URL and HTTP method, including the necessary authorization token
    private func createRequest(
        with url: URL?,
       type: HTTPMethod,
       completion: @escaping (URLRequest) -> Void
    ) {
        AuthManager.shared.withValidToken{ token in     //ensures a valid api toke nis available
            guard let apiURL = url else {
                return
            }
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
        
    }
}
