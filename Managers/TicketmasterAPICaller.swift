//
//  TicketmasterAPICaller.swift
//  musictime
//
//  Created by Aamax Lee on 21/5/2024.
//

import Foundation
import CoreLocation

//similair to spotify api caller, but for ticketmaster to obtain events near user lcation
final class TicketmasterAPICaller {
    // Singleton instance of TicketmasterAPICaller
        static let shared = TicketmasterAPICaller()
    // Set to store unique event IDs to prevent duplicates
        private var uniqueEventIDs: Set<String> = []
    
    private init() {}
    
//    apiurl call for ticketmaster, along with apikey and pages per call
    struct Constants {
        static let baseAPIURL = ""
        static let apiKey = ""
        static let pageLimit = 5
    }
    
    enum APIError: Error {
        case failedToGetData
    }
     
//    Retrieves events near a specified location and page
    public func getEvents(near location: CLLocation, page: Int, completion: @escaping (Result<[Event], Error>) -> Void) {
            let apiKeyParameter = "apikey=\(Constants.apiKey)"
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            let urlString = "\(Constants.baseAPIURL)/events.json?\(apiKeyParameter)&latlong=\(lat),\(lon)&size=\(Constants.pageLimit)&page=\(page)" //call url
            
            guard let url = URL(string: urlString) else {
                completion(.failure(APIError.failedToGetData))
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(TicketmasterResponse.self, from: data)
                    let events = result._embedded.events
                    let uniqueEvents = events.filter { event in     //ensures we dont add duplicate events (duplicate names)
                        let isNewEvent = !self.uniqueEventIDs.contains(event.name)
                        if isNewEvent {
                            self.uniqueEventIDs.insert(event.name)
                        }
                        return isNewEvent
                    }
 
                    uniqueEvents.forEach { self.uniqueEventIDs.insert($0.name) }
                    completion(.success(uniqueEvents))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    
    
    
    
    }
     
