//
//  ProfileViewController.swift
//  musictime
//
//  Created by Aamax Lee on 25/4/2024.
//

import UIKit

//View controller for displaying user profile information, specifically users top artists and songs
class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate {
    
    @IBOutlet weak var QOTDStreak: UILabel!     //label for total qotd submissions by user
    @IBOutlet weak var SOTDStreak: UILabel!     //label for total sotd submissions by user
    @IBOutlet weak var userImage: UIImageView!  //Image view displaying the user profile picture
    @IBOutlet weak var userName: UILabel!       //label for user's username
    
    @IBOutlet weak var topArtistsCollectionView: UICollectionView!      //collectionview used to display user's top artists in a row
    
    @IBOutlet weak var topTracksCollectionView: UICollectionView!        //collectionview used to display user's top songs in a row
    var appDelegate: AppDelegate?
    
    var topArtists: [ArtistObject] = []     //arrays to contain the user's top trakcs and artists
    var topTracks: [TrackObject] = []
    
    var database: DatabaseProtocol?     //reference to database controller instance for accessing user data
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        self.database = appDelegate?.databaseController
        
//        update the sotd and qotd streak labels with the data from firestore
        self.database?.getSOTDStreak { SOTDStreak in
            self.SOTDStreak.text = String(SOTDStreak)
        }
        
        self.database?.getQOTDStreak { QOTDStreak in
            self.QOTDStreak.text = String(QOTDStreak)
        }
         
    }
    
//    Configures UI elements and fetches user data upon view load
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        Fetch user's top artists and top tracks from the API
        APICaller.shared.getUserTopArtists { [weak self] result in
                    switch result {
                    case .success(let userTopArtists):
                        // Update the data source with user's top artists, then reload the table to display top artists
                        self?.topArtists = userTopArtists.items
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.topArtistsCollectionView.reloadData()
                        }
                        
                    case .failure(let error):
                        print("Failed to get user's top artists: \(error)")
                    }
                }
        
        APICaller.shared.getUserTopTracks { [weak self] result in
                    switch result {
                    case .success(let userTopArtists):
                        self?.topTracks = userTopArtists.items
                        // Update the data source with user's top songs, then reload the table to display top songs and artists (prevent one side not showing)
                        DispatchQueue.main.async { [weak self] in
                            self?.topTracksCollectionView.reloadData()
                            self?.topArtistsCollectionView.reloadData()
                        }
                        
                    case .failure(let error):
                        print("Failed to get user's top tracks: \(error)")
                    }
                }
            
        // Set background color and gradient layer
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0), UIColor.black.cgColor]
        view.layer.insertSublayer(layer, at: 0)
        
        self.appDelegate = UIApplication.shared.delegate as? AppDelegate
        
//        grab username from userdefaults to display in proifle
        guard let userName = UserDefaults.standard.string(forKey: "userName"), let userImage = UserDefaults.standard.string(forKey: "userImage") else {
            print("User ID not found in UserDefaults")
            return
        }
        self.userName.text = userName
        
        if let imageUrl = URL(string: userImage) {
            // Create a URLSession task to download the image data
            let task = URLSession.shared.dataTask(with: imageUrl) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                // Convert the downloaded data to a UIImage object
                if let image = UIImage(data: data) {
                    // Update the UI on the main thread
                    DispatchQueue.main.async {
                        // Set the image to the UIImageView
                        self.userImage.image = image
                        self.userImage.layer.cornerRadius = self.userImage.frame.size.width / 2
                        self.userImage.clipsToBounds = true
                    }
                } else {
                    print("Unable to create image from data")
                }
            }
            // Start the URLSession task
            task.resume()
        } else {
            print("Invalid URL")
        }
     
//        swtup the collection views and ensure the scrollbar does not show for visuals
        topArtistsCollectionView.dataSource = self
        topArtistsCollectionView.delegate = self
        
        topArtistsCollectionView.showsVerticalScrollIndicator = false
        topArtistsCollectionView.showsHorizontalScrollIndicator = false
        
        topTracksCollectionView.dataSource = self
        topTracksCollectionView.delegate = self
        
        topTracksCollectionView.showsVerticalScrollIndicator = false
        topTracksCollectionView.showsHorizontalScrollIndicator = false
        
        
          
        let layout = NoVerticalScrollFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 80, height: 100)
            layout.minimumLineSpacing = 5

           
        topArtistsCollectionView.collectionViewLayout = layout
        topTracksCollectionView.collectionViewLayout = layout
        
    }
    
//    ensure collection views are properly separated with their counts
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == topArtistsCollectionView {
            return topArtists.count
        }
        return topTracks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        for top artist collection view, set images and names appropriately
        if collectionView == topArtistsCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArtistCell", for: indexPath) as? ProfileCollectionViewCell else {
                fatalError("Unable to dequeue ArtistCollectionViewCell")
            }
            
            let artist = topArtists[indexPath.item]
            cell.label.text = artist.name
            
            if let imageURL = URL(string: artist.images.last?.url ?? "") {
                URLSession.shared.dataTask(with: imageURL) { data, _, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.imageView.image = image
                            
                        }
                    } else {
                        print("Failed to load artist image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }.resume()
            }
             
            return cell
            
//             for top songs collection view, set images and names appropriately
        } else if collectionView == topTracksCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackCell", for: indexPath) as? ProfileTracksCollectionViewCell else {
                fatalError("Unable to dequeue ArtistCollectionViewCell")
            }
            let track = topTracks[indexPath.item]
            cell.label.text = track.name
            
            if let imageURL = URL(string: track.album.images.first?.url ?? "") {
                URLSession.shared.dataTask(with: imageURL) { data, _, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.imageView.image = image
                            
                        }
                    } else {
                        print("Failed to load artist image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }.resume()
            }
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    
//    settings button to perform logout
    @IBAction func settingsButtonPress(_ sender: Any) {
        // Create the alert controller
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            // Add a sign out action
            let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { _ in
                
                let logoutURL = URL(string: "https://accounts.spotify.com/logout")!

                    // Create a logout request
                    var logoutRequest = URLRequest(url: logoutURL)
                    logoutRequest.httpMethod = "GET"

                    // Perform the logout request
                    let session = URLSession.shared
                    let task = session.dataTask(with: logoutRequest) { data, response, error in
                        if let error = error {
                            print("Logout failed: \(error.localizedDescription)")
                            return
                        }
                        
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                            print("Logout successful")
                            if let appDomain = Bundle.main.bundleIdentifier {
                                UserDefaults.standard.removePersistentDomain(forName: appDomain)        //remove all userdefaults for fresh state
                            }
                            DispatchQueue.main.async {
                            }
                        } else {
                            print("Logout failed: Unexpected response")
                        }
                    }
                    task.resume()
                
                self.performSegue(withIdentifier: "signOutSegue", sender: nil)  //send user back to signin screen
            }
            alertController.addAction(signOutAction)
            
            // Add a cancel action
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            // Present the alert controller
            present(alertController, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


class NoVerticalScrollFlowLayout: UICollectionViewFlowLayout {
     func collectionViewContentSize() -> CGSize {
        guard let collectionView = collectionView else { return .zero }
        let contentHeight = collectionView.bounds.height
        let contentWidth = collectionView.contentSize.width
        return CGSize(width: contentWidth, height: contentHeight)
    }
}
