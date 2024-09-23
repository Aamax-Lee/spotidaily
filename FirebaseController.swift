//
//  FirebaseController.swift
//  musictime
//
//  Created by Aamax Lee on 21/4/2024.
//

//import Foundation
import UIKit
//import FirebaseFirestoreSwift
//import FirebaseFirestore
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage
//import FirebaseFirestoreSwift

//general class to handle calls to firestore
class FirebaseController: NSObject, DatabaseProtocol {
     
    var database: Firestore
    var authController: Auth
    var userId: String?
    var userName: String?
    
    let defaults = UserDefaults.standard
    
    override init() {
        FirebaseApp.configure()
        database = Firestore.firestore()
        authController = Auth.auth()
        super.init()
    }
    
//    obtain user id
    func getUserId() -> String {
        return self.userId ?? "No user id"
    }
    
    
     
    
    func createUserDocument(userId: String) {
//         depreciated function
    }
    
//    signs user into firestore to access data and set userdefaults to be retirved in later use
    func storeSpotifyUserID(userID: String, email: String, name: String, userImage: String) {
        self.userId = userID
        self.defaults.set(userID, forKey: "userId")
        self.defaults.set(name, forKey: "userName")
        self.defaults.set(userImage, forKey: "userImage")
        print(userImage)
        self.userName = name
        
        authController.signIn(withEmail: email, password: userID) { (authDataResult, error) in
            if authDataResult != nil {
            } else if error != nil {
                
                self.authController.createUser(withEmail: email, password: userID) { (authDataResult, error) in
                    if authDataResult != nil {
                        self.createUserDocument(userId: userID)
                    } else if error != nil {
                    }
                }
            }
        }
         
    }
    
//    get the sotd (and quote) of the day
    func getSOTDofTheDay(completion: @escaping (SOTD?) -> Void) {
        let sotd = SOTD()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time

        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        let documentID = "\(formattedDate)itemsoftheday"

        let itemRef = database.collection("itemOfTheDay").document(documentID)  //in itemoftheday collection, each document id contains the date to ensure qotd and sotd changes daily

        itemRef.getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                print("Error fetching document: \(String(describing: error))")
                completion(nil) // Call the completion handler with nil if there's an error
                return
            }

            // Extract data from Firestore document
            guard let songName = data["songName"] as? String,
                  let artistName = data["artistName"] as? String,
                  let quote = data["quote"] as? String,
                  let imageURLString = data["image"] as? String else {
                print("Error: Unable to parse document data")
                completion(nil) // Call the completion handler with nil if data parsing fails
                return
            }

            // Update SOTD object with fetched data
            sotd.name = songName
            sotd.artist = artistName
            sotd.image = imageURLString 
            sotd.quote = quote

            completion(sotd) // Call the completion handler with the fetched SOTD object
        }
    }
    
    

//    Function to upload a video to Firebase Storage and store metadata in Firestore
    func uploadVideoToFirebase(videoURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time

        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
        
//         Retrieve user image from UserDefaults
        guard let userImage = self.defaults.string(forKey: "userImage") else {
            return
        }
            
//        reference to the Firebase Storage location for the video
            let storageRef = Storage.storage().reference().child("videos").child("\(UUID().uuidString).mp4")
            let videoPath = storageRef.fullPath
        
//        Upload video to Firebase Storage
            storageRef.putFile(from: videoURL, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(false, error)
                    return
                }
                
//                Retrieve download URL for the uploaded video
                storageRef.downloadURL { (url, error) in
                    if let downloadURL = url {
                        
//                        Reference to the Firestore document for the uploaded video
                        let uploadsRef = self.database.collection("SOTDVideoUploads").document(formattedDate + "SOTDUploads")
                        let sotdRef = uploadsRef.collection("SOTD").document(self.userId!)
                        
                        let data: [String: Any] = [ //Data to be stored in Firestore
                            "userVideo": videoPath,
                            "userName": self.userName!,
                            "userImage": userImage
                        ]
                        
                        sotdRef.setData(data, merge: true) { error in   //set data in Firestore document
                            if let error = error {
                                print("Error updating user document: \(error)")
                                completion(false, error)
                            } else {
                                print("User document updated successfully.")
                                completion(true, nil)
                            }
                        }
                    } else {
                        print("Error getting download URL: \(String(describing: error))")
                        completion(false, error)
                    }
                }
                 
                
                
            }
        }
    
    
    //Function to upload an image to Firebase Storage and store metadata in Firestore
    func uploadImageToFirebase(imageURL: URL, track: TrackObject, completion: @escaping (Bool, Error?) -> Void) {
        guard let imageData = try? Data(contentsOf: imageURL) else {
            print("Failed to load image data.")
            let error = NSError(domain: "com.example.app", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data."])
            completion(false, error)
            return
        }
        //extract track information
        let title = track.name
        let imageURL =  track.album.images.first?.url ?? ""
        let subtitle = track.artists.first?.name ?? "-"
         
//        Retrieve user image from UserDefaults
        guard let userImage = self.defaults.string(forKey: "userImage") else {
            print("User image not found.")
            let error = NSError(domain: "com.example.app", code: 401, userInfo: [NSLocalizedDescriptionKey: "User image not found."])
            completion(false, error)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time

        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
//        reference to the Firebase Storage location for the image
        let storageRef = Storage.storage().reference().child("images").child("\(UUID().uuidString).jpg")
        let imagePath = storageRef.fullPath
        
//        Upload image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(false, error)
                return
            }
            
//            Reference to the Firestore document for the uploaded image
            let uploadsRef = self.database.collection("QOTDImageUploads").document(formattedDate + "QOTDUploads")
            let sotdRef = uploadsRef.collection("QOTD").document(self.userId!)
            
//            Retrieve download URL for the uploaded image
            storageRef.downloadURL { (url, error) in
                if let downloadURL = url {
                    print("Image uploaded successfully. Download URL: \(downloadURL)")
                    sotdRef.setData(["userImage": userImage, "userName": self.userName!, "imageData": imagePath, "trackName": title, "trackArtist": subtitle, "trackImage": imageURL], merge: true) { error in
                        if let error = error {
                            print("Error updating user document: \(error)")
                            completion(false, error)
                        } else {
                            print("User document updated successfully.")
                            completion(true, nil)
                        }
                    }
                } else {
                    print("Error getting download URL: \(String(describing: error))")
                    completion(false, error)
                }
            }
        }
    }
 
//    Function to check if a user-submitted video exists
    func checkUserSubmittedVideoExists(completion: @escaping (Bool, String?, URL?) -> Void) {
        guard let userId = self.defaults.string(forKey: "userId") else {
            completion(false, nil, nil) // User ID is nil, return false
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time
        let formattedDate = dateFormatter.string(from: Date())
        
        let userVideoRef = database.collection("SOTDVideoUploads").document(formattedDate + "SOTDUploads").collection("SOTD").document(userId)
        
        userVideoRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching document: \(error)")
                completion(false, nil, nil)
                return
            }

            guard let document = document, document.exists else {
                print("Document does not exist")
                completion(false, nil, nil)
                return
            }
            
            // Video document exists
            if let data = document.data(),
               let userName = data["userName"] as? String,
               let videoReference = data["userVideo"] as? String {
                // Get the download URL for the video reference
                Storage.storage().reference().child(videoReference).downloadURL { (url, error) in
                    if let url = url {
                        completion(true, userName, url)
                    } else {
                        completion(false, nil, nil) // Unable to get video URL
                    }
                }
            } else {
                print("Unable to parse user name or video reference")
                completion(false, nil, nil)
            }
        }
    }
 

//    function to fetch all videos from Firestore (for sotd)
    func fetchVideosFromFirestore(completion: @escaping ([(userName: String, videoURL: URL, userImage: String)]) -> Void) {
//
        var videos: [(userName: String, videoURL: URL, userImage: String)] = []

        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found in UserDefaults")
            completion([])
            return
        }
        
        
        let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
       dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time
       let formattedDate = dateFormatter.string(from: Date())

           self.database.collection("SOTDVideoUploads").document(formattedDate + "SOTDUploads").collection("SOTD").getDocuments { (snapshot, error) in
                
            if let error = error {
                print("Error fetching documents: \(error)")
                completion([])
                return
            }
            
            
            // Process fetched documents
            guard let snapshot = snapshot else {
                print("Error fetching documents:")
                completion([])
                return
            }
            
            var userVideoIndex: Int? = nil
            
            for (index, document) in snapshot.documents.enumerated() {
                
                if let userName = document["userName"] as? String,
                   let videoReference = document["userVideo"] as? String,
                    let userImage = document["userImage"] as? String {
                    // Get download URL for video reference
                    Storage.storage().reference().child(videoReference).downloadURL { (url, error) in
                        if let url = url {
                            // Check if the document ID matches the user ID
                            if document.documentID == userId {
                                // Store the index of the user's video
                                userVideoIndex = index
                                
                                // Store user's video information in persistent storage
                                UserDefaults.standard.set(["userName": userName, "videoURL": url.absoluteString, "userImage": userImage], forKey: "SOTDuserVideo")
//                                videos.append((userName: userName, videoURL: url))
                            }
                                // Add other users' video data to array
                            videos.append((userName: userName, videoURL: url, userImage: userImage))
                            print("index: ", index, " username: ", userName)
//                            print()
                            
                            
                            // If all videos are fetched, call completion handler
                            if videos.count == snapshot.documents.count {
                                
                                if userVideoIndex == nil {
                                    UserDefaults.standard.set("", forKey: "SOTDuserVideo")
                                } else {
                                    
                                    if let userVideoURLString = UserDefaults.standard.dictionary(forKey: "SOTDuserVideo") {
                                        //ensures user submited video doesnt appear in list of other users submissions
                                        if let userVideoIndex = videos.firstIndex(where: { $0.videoURL.absoluteString == userVideoURLString["videoURL"] as? String }) {
                                            videos.remove(at: userVideoIndex)
                                        }
                                    }
                                }
                                completion(videos)
                            }
                        } else {
                            print("Error getting video URL: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
        }
         
        completion([])
    }
    
     
//    function to fetch all images from Firestore (for qotd)
    func fetchImagesFromFirestore(completion: @escaping ([(userName: String, imageURL: URL, userImage: String, trackImage: String, trackName: String, trackArtist: String)]) -> Void) {
        var images: [(userName: String, imageURL: URL, userImage: String, trackImage: String, trackName: String, trackArtist: String)] = []

        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found in UserDefaults")
            completion([])
            return
        }
        
        let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
       dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time
       let formattedDate = dateFormatter.string(from: Date())

       self.database.collection("QOTDImageUploads").document(formattedDate + "QOTDUploads").collection("QOTD").getDocuments { (snapshot, error) in

//        self.database.collection("QOTDImageUploads").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                completion([])
                return
            }
            
            // Process fetched documents
            guard let snapshot = snapshot else {
                print("Error fetching documents:")
                completion([])
                return
            }
            
            if snapshot.documents.count == 0 {
                UserDefaults.standard.removeObject(forKey: "QOTDUserImage")
                print("set to nil ")
            }
            
            for document in snapshot.documents {
                guard let userName = document["userName"] as? String,
                      let imageURLString = document["imageData"] as? String,
                      let userImage = document["userImage"] as? String,
                      let trackImageString = document["trackImage"] as? String,
                      let trackName = document["trackName"] as? String,
                      let trackArtist = document["trackArtist"] as? String
                      
                else {
                    continue
                }
                Storage.storage().reference().child(imageURLString).downloadURL { (url, error) in
                    
                    if let url {
                        print(url)
                        if document.documentID == userId {
                            
                            UserDefaults.standard.set(["userName": userName, "imageURL": url.absoluteString, "userImage": userImage, "trackImage": trackImageString, "trackName": trackName, "trackArtist": trackArtist], forKey: "QOTDUserImage")
                        }
                        images.append((userName: userName, imageURL: url, userImage: userImage, trackImage: trackImageString, trackName: trackName, trackArtist: trackArtist))
                    } else if let error {
                        print(error)
                    }
                    
                    
                    if images.count == snapshot.documents.count {
                                    if let userVideoURLString = UserDefaults.standard.dictionary(forKey: "QOTDUserImage") {
                                        //ensures user submited video doesnt appear in list of other users submissions
                                        if let userVideoIndex = images.firstIndex(where: { $0.imageURL.absoluteString == userVideoURLString["imageURL"] as? String }) {
                                            images.remove(at: userVideoIndex)
                                        } else {
                                            UserDefaults.standard.removeObject(forKey: "QOTDUserImage")
                                            print("set to nil ")
                                        }
                                    }
                        completion(images)
                    }
                }
            }
        }
        UserDefaults.standard.removeObject(forKey: "QOTDUserImage")
        print("set to nil ")
        completion([])
    }
 
    
//    remove user's submission from firestorw (for sotd)
    func deleteUserSOTDFromFirestore(completion: @escaping (Error?) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found in UserDefaults")
            completion(nil) // Return without performing deletion if user ID is not found
            return
        }
        
        let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
       dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time
       let formattedDate = dateFormatter.string(from: Date())
        // Reference to the Firestore collection
        let collectionRef =   self.database.collection("SOTDVideoUploads").document(formattedDate + "SOTDUploads").collection("SOTD")
        
        
        
        // Delete the document with the user's ID
        collectionRef.document(userId).delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
                completion(error)
            } else {
                print("Document successfully deleted")
                // Perform any additional cleanup if needed
                completion(nil)
            }
        }
    }
    
    //    remove user's submission from firestore (for qotd)
    func deleteUserQOTDFromFirestore(completion: @escaping (Error?) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found in UserDefaults")
            completion(nil) // Return without performing deletion if user ID is not found
            return
        }
        
        let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyyMMdd" // Format the date as YYYYMMDD
       dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney") // Set the time zone to Australian time
       let formattedDate = dateFormatter.string(from: Date())
        // Reference to the Firestore collection
        let collectionRef =   self.database.collection("QOTDImageUploads").document(formattedDate + "QOTDUploads").collection("QOTD")
        
       
        
        // Delete the document with the user's ID
        collectionRef.document(userId).delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
                completion(error)
            } else {
                print("Document successfully deleted")
                // Perform any additional cleanup if needed
                completion(nil)
            }
        }
    }
     
//    set sotd treak as 0
    func resetSOTDStreak() {
        guard let userId = self.defaults.string(forKey: "userId") else {
//            completion(false, nil, nil) // User ID is nil, return false
            return
        }
        let userRef = database.collection("Users").document(userId)
        
        // Check if the user document already exists
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the SOTDStreak field to 0
                userRef.updateData(["SOTDStreak": 0]) { error in
                    if let error = error {
                        print("Error updating user document: \(error)")
                    } else {
                        print("SOTDStreak field updated successfully for user \(String(describing: userId))")
                    }
                }
            } else {
                // Document doesn't exist, create a new user document with SOTDStreak set to 0
                userRef.setData(["spotifyId": userId, "SOTDStreak": 0]) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully for user \(String(describing: userId)) with SOTDStreak initialized to 0")
                    }
                }
            }
        }
    }
    
//    increment sotd strak by 1
    func increaseSOTDStreak() {
        guard let userId = self.defaults.string(forKey: "userId") else {
            return
        }
        let userRef = database.collection("Users").document(userId)
        
        // Check if the user document already exists
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the SOTDStreak field to 0
                userRef.updateData(["SOTDStreak": FieldValue.increment(Int64(1))]) { error in       //increment by 1
                    if let error = error {
                        print("Error updating user document: \(error)")
                    } else {
                        print("SOTDStreak field updated successfully for user \(String(describing: userId))")
                    }
                }
            } else {
                // Document doesn't exist, create a new user document with SOTDStreak set to 0
                userRef.setData(["spotifyId": userId, "SOTDStreak": 1]) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully for user \(String(describing: userId)) with SOTDStreak initialized to 0")
                    }
                }
            }
        }
    }
    
//    decrease sotd streak by 1
    func decreaseSOTDStreak() {
        guard let userId = self.defaults.string(forKey: "userId") else {
//            completion(false, nil, nil) // User ID is nil, return false
            return
        }
        let userRef = database.collection("Users").document(userId)
        
        // Check if the user document already exists
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the SOTDStreak field to 0
                userRef.updateData(["SOTDStreak": FieldValue.increment(Int64(-1))]) { error in      //decrease by 1
                    if let error = error {
                        print("Error updating user document: \(error)")
                    } else {
                        print("SOTDStreak field updated successfully for user \(String(describing: userId))")
                    }
                }
            } else {
                // Document doesn't exist, create a new user document with SOTDStreak set to 0
                userRef.setData(["spotifyId": userId, "SOTDStreak": 1]) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully for user \(String(describing: userId)) with SOTDStreak initialized to 0")
                    }
                }
            }
        }
    }
    
    
//get sotd dtreak number
    func getSOTDStreak(completion: @escaping (Int) -> Void) {
        guard let userId = self.defaults.string(forKey: "userId") else {
            completion(0)
            return
        }
        let userRef = database.collection("Users").document(userId)
         

        userRef.getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                print("Error fetching document: \(String(describing: error))")
                completion(0) // Call the completion handler with nil if there's an error
                return
            }

            guard let sotdStreak = data["SOTDStreak"] as? Int else {
                completion(0)
                return
            }
            completion(sotdStreak)
        }
    }
    
    
    //    increment qotd strak by 1
    func increaseQOTDStreak() {
        guard let userId = self.defaults.string(forKey: "userId") else {
//            completion(false, nil, nil) // User ID is nil, return false
            return
        }
        let userRef = database.collection("Users").document(userId)
        
        // Check if the user document already exists
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the SOTDStreak field to 0
                userRef.updateData(["QOTDStreak": FieldValue.increment(Int64(1))]) { error in
                    if let error = error {
                        print("Error updating user document: \(error)")
                    } else {
                        print("QOTDStreak field updated successfully for user \(String(describing: userId))")
                    }
                }
            } else {
                // Document doesn't exist, create a new user document with SOTDStreak set to 0
                userRef.setData(["spotifyId": userId, "QOTDStreak": 1]) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully for user \(String(describing: userId)) with QOTDStreak initialized to 0")
                    }
                }
            }
        }
    }
    
//    decrease qotd steak by 1
    func decreaseQOTDStreak() {
        guard let userId = self.defaults.string(forKey: "userId") else {
//            completion(false, nil, nil) // User ID is nil, return false
            return
        }
        let userRef = database.collection("Users").document(userId)
        
        // Check if the user document already exists
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the SOTDStreak field to 0
                userRef.updateData(["QOTDStreak": FieldValue.increment(Int64(-1))]) { error in
                    if let error = error {
                        print("Error updating user document: \(error)")
                    } else {
                        print("QOTDStreak field updated successfully for user \(String(describing: userId))")
                    }
                }
            } else {
                // Document doesn't exist, create a new user document with SOTDStreak set to 0
                userRef.setData(["spotifyId": userId, "QOTDStreak": 1]) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully for user \(String(describing: userId)) with QOTDStreak initialized to 0")
                    }
                }
            }
        }
    }
    
    
//get qotd streak number
    func getQOTDStreak(completion: @escaping (Int) -> Void) {
        guard let userId = self.defaults.string(forKey: "userId") else {
//            completion(false, nil, nil) // User ID is nil, return false
            completion(0)
            return
        }
        let userRef = database.collection("Users").document(userId)
         

        userRef.getDocument { (document, error) in
            guard let document = document, document.exists, let data = document.data() else {
                print("Error fetching document: \(String(describing: error))")
                completion(0) // Call the completion handler with nil if there's an error
                return
            }

            guard let sotdStreak = data["QOTDStreak"] as? Int else {
                completion(0)
                return
            }
            completion(sotdStreak)
        }
    }
             
    
    func cleanup() {
        
    }
    
    func addListener(listener: DatabaseListener) {
        
    }
    
    func removeListener(listener: DatabaseListener) {
        
    }
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        
    }
    
    func signup(email: String, password: String, completion: @escaping (Bool) -> Void) {
        
    }
    
    
} 
