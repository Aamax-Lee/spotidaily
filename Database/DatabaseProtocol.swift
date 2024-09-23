//
//  DatabaseProtocol.swift
//  FIT3178-W03-Lab
//
//  Created by Aamax Lee on 20/3/2024.
//

import Foundation

//define what type of change has been done to the database
enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case team
    case heroes
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
     

}

protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
     
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void)
    func signup(email: String, password: String, completion: @escaping (Bool) -> Void)

    func storeSpotifyUserID(userID: String, email: String, name: String, userImage: String)
     
    func getSOTDofTheDay(completion: @escaping (SOTD?) -> Void)
     
    func uploadVideoToFirebase(videoURL: URL, completion: @escaping (Bool, Error?) -> Void)
    func checkUserSubmittedVideoExists(completion: @escaping (Bool, String?, URL?) -> Void)
    func fetchVideosFromFirestore(completion: @escaping ([(userName: String, videoURL: URL, userImage: String)]) -> Void)
    func deleteUserSOTDFromFirestore(completion: @escaping (Error?) -> Void)
    func getUserId() -> String
    
    func resetSOTDStreak()
    func increaseSOTDStreak()
    func decreaseSOTDStreak()
    func getSOTDStreak(completion: @escaping (Int) -> Void)
     
    func increaseQOTDStreak()
    func decreaseQOTDStreak()
    func getQOTDStreak(completion: @escaping (Int) -> Void)
    
    func uploadImageToFirebase(imageURL: URL, track: TrackObject, completion: @escaping (Bool, Error?) -> Void)
    func fetchImagesFromFirestore(completion: @escaping ([(userName: String, imageURL: URL, userImage: String, trackImage: String, trackName: String, trackArtist: String)]) -> Void)
    func deleteUserQOTDFromFirestore(completion: @escaping (Error?) -> Void)
}


