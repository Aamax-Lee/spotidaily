//
//  QOTDViewController.swift
//  musictime
//
//  Created by Aamax Lee on 25/4/2024.
//

import UIKit
import FirebaseStorage
import MobileCoreServices
import AVFoundation
import UIKit
import AVKit




/*
 The `QOTDViewController` is responsible for displaying the Quote of the Day (QOTD) and managing user interactions with the QOTD and image uploads.
 It handles fetching images from Firestore, displaying them in a table view, and allowing users to upload their own images.
 */
class QOTDViewController: UIViewController, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate {
    
    
    @IBOutlet weak var QOTDLabel: UILabel!  //Label text to display quote of the day
    
    var database: DatabaseProtocol?     //database protocol to use firestore functions
    let defaults = UserDefaults.standard        //user defualts
    let imagePicker = UIImagePickerController()     //image picker class that we can use to pick images from user's gallery
    
    var images: [(userName: String, imageURL: URL, userImage: String, trackImage: String, trackName: String, trackArtist: String)] = []
    //    array of uploaded images from users
    
    private let refreshControl = UIRefreshControl()     //allows us to refresh the table on drag down
    
    let SECTION_UPLOAD = 0  //first section of table is either a button that lets user upload, or displays the user's upload
    let SECTION_IMAGES = 1  //all other user's uploads
    
    var pickingimage = false       //checker variable to ensure button stops working after user uploads an image
    
    var track: TrackObject?     //track object that stores the track user has selected
    //    currently not being used, for future implementation extension or debugging
    
    @IBOutlet weak var qotdTable: UITableView!      //table object of the tab
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        sets background color of the tab
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0), UIColor.black.cgColor]
        view.layer.insertSublayer(layer, at: 0)
        
        //        references to appdelegate of the app to access the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        self.database = appDelegate?.databaseController     //reference to database controller
        
        qotdTable.dataSource = self
        qotdTable.delegate = self
        
        self.database?.fetchImagesFromFirestore() { [weak self] fetchedImages in
            // Assign fetched images to self.images, then reloads the table
            self?.images = fetchedImages
            DispatchQueue.main.async {
                self?.qotdTable.reloadData()
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.database?.fetchImagesFromFirestore() { [weak self] fetchedImages in
            // Assign fetched images to self.images, then reloads the table
            self?.images = fetchedImages
            DispatchQueue.main.async {
                self?.qotdTable.reloadData()
            }
        }
        
        //        sets the label text to the quote of the dsy
        self.database?.getSOTDofTheDay {sotd in
            if let sotd = sotd {
                self.defaults.set(sotd.quote, forKey: "QOTD")
            }
            self.QOTDLabel.text = sotd?.quote
        }
        
        //        redirect the user to the screen that displays today's qotd if required
        redirectIfNeeded()
        
    }
    
    func redirectIfNeeded() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let australiaCalendar = Calendar(identifier: .gregorian)
        let australiaDate = australiaCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate)!
        
        if currentDate > australiaDate {
            // Check if the user has been redirected today
            let lastRedirectDate = UserDefaults.standard.value(forKey: "QOTDLastRedirectDate") as? Date ?? Date.distantPast
            let lastRedirectDay = calendar.startOfDay(for: lastRedirectDate)
            let currentDay = calendar.startOfDay(for: currentDate)
            
            if currentDay > lastRedirectDay {
                // Redirect the user to the new view controller
                UserDefaults.standard.set(currentDate, forKey: "QOTDLastRedirectDate")
                performSegue(withIdentifier: "QOTDTodayVCSegue", sender: nil)
            } else {
                //                do nothing
            }
        }
    }
    
    
    //     if user presses uplaod button, show alert with option to choose from gallery or cancel action
    @IBAction func onPressUpload(_ sender: Any) {
        if self.pickingimage {      //ensures button isn't press multiple times
            return
        } else {
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let uploadAction = UIAlertAction(title: "Photo & Video Lbrary", style: .default) { _ in     //first option in alert, calls pickPictureFromGallery function on press
                self.pickPictureFromGallery()
            }
            
            alertController.addAction(uploadAction)
            
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)     //second option in alert, cancels action
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    
    func pickPictureFromGallery() {
        self.pickingimage = true        //lets app know user is picking image, upload image button cease function
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [UTType.image.identifier]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
        //        shows view for user to pick image from gallery
    }
    
    //    after user picks image, convert image data to URL and send to search view controller for user to pick song to uplaod along with image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaType = info[.mediaType] as? String {
            if mediaType == UTType.image.identifier {
                if let imageURL = info[.imageURL] as? URL {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toSearchViewSegue", sender: imageURL)
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    //    sends user uplaoded image URL to search view controller for user to pick song to upload along with image
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSearchViewSegue" {
            if let navigationController = segue.destination as? UINavigationController,
               let destinationVC = navigationController.topViewController as? SearchViewController,
               let imageURL = sender as? URL {
                destinationVC.imageURL = imageURL
            }
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    //    set appropriate height of cells i ntable
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //        section upload: if user uploaded, same height as other user uploads cells, if not, set height to 80 to only accustom for upload button
        if indexPath.section == SECTION_UPLOAD {
            guard let videoInfo = UserDefaults.standard.dictionary(forKey: "QOTDUserImage"),
                  let userName = videoInfo["userName"] as? String,
                  let imageURLString = videoInfo["imageURL"] as? String,
                  let userImageString = videoInfo["userImage"] as? String
            else {
                return 80   //button cell height
            }
            return 315
            
        } else if indexPath.section == SECTION_IMAGES {
            return 315
        }
        return 25
    }
    
    //    user upload section will always be 1 cell, other user's uplaods section cells will be same as number of other user uplaods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_UPLOAD {
            return 1
        } else if section == SECTION_IMAGES {
            return images.count
        }
        return 0
    }
    
    //    controls what cells to display
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_UPLOAD {
            //            all variables below are all the information to display in a single cell (if user did upload an image along with a chosen song)
            if let userImageInfo = UserDefaults.standard.dictionary(forKey: "QOTDUserImage"),
               let userName = userImageInfo["userName"] as? String,
               let imageURLString = userImageInfo["imageURL"] as? String,
               let userImageString = userImageInfo["userImage"] as? String,
               let trackName = userImageInfo["trackName"] as? String,
               let trackArtist = userImageInfo["trackArtist"] as? String,
               let trackImage = userImageInfo["trackImage"] as? String,
               let imageURL = URL(string: imageURLString) {
                
                //                let upload song be ImageTableViewCell else return regular table view cell
                guard let uploadCell = tableView.dequeueReusableCell(withIdentifier: "UploadCell", for: indexPath) as? ImageTableViewCell else {
                    return UITableViewCell()
                }
                
                //                create task to download user submitted image from fiebase storage
                let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                    guard let data = data, error == nil else {      //error in retrieving image from storage
                        print("Failed to download image:", error?.localizedDescription ?? "Unknown error")
                        return
                    }
                    // Create UIImage from downloaded data
                    if let image = UIImage(data: data) {
                        // Set the image to the imageView on the main thread
                        DispatchQueue.main.async {
                            uploadCell.imageDisplayView.image = image
                        }
                    } else {        //error in turning image data into UIImage
                        print("Failed to create image from downloaded data")
                    }
                }
                task.resume()
                
                //                hide upload button
                //                unhide cell that contains user information and uploaded image and song data
                //                (also load image into the cell)
                uploadCell.qotdButton.isHidden = true
                uploadCell.usernameLabel.isHidden = false
                uploadCell.usernameLabelText(username: userName)
                uploadCell.userImageString = userImageString
                uploadCell.loadImageFromURL()
                uploadCell.imageDisplayView.isHidden = false
                uploadCell.imageContainerView.isHidden = false
                
                uploadCell.trackTitleLabel.text = trackName
                uploadCell.trackArtistLabel.text = trackArtist
                uploadCell.trackImageString = trackImage
                uploadCell.loadTrackImageFromURL()
                
                return uploadCell
                
            } else {
                // Handle case when user uploaded image info is not available (user did not upload an image)
                // Return a ImageTableViewCell (same cell type that dsplays other user sumissions)
                guard let uploadCell = tableView.dequeueReusableCell(withIdentifier: "UploadCell", for: indexPath) as? ImageTableViewCell else {
                    return UITableViewCell()
                }
                
                //                show upload button and hide other data
                uploadCell.hideImage()
                uploadCell.qotdButton.isHidden = false
                uploadCell.usernameLabel.isHidden = true
                return uploadCell
            }
            
        } else if indexPath.section == SECTION_IMAGES {     //all cells are sumbissions from other users
            
            //            ImageTableViewCell displays submission data appropriately
            guard let videoCell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as? ImageTableViewCell else {
                return UITableViewCell()
            }
            
            let imageData = images[indexPath.row]       //imageData contains submission data for each row iteration
            
            //            set username and image data appropriately
            videoCell.usernameLabelText(username: imageData.userName)
            videoCell.userImageString = imageData.userImage
            videoCell.loadImageFromURL()
            
            //            set song name, artist name and image data appropriately too
            videoCell.trackTitleLabel.text = imageData.trackName
            videoCell.trackArtistLabel.text = imageData.trackArtist
            videoCell.trackImageString = imageData.trackImage
            videoCell.loadTrackImageFromURL()
            
            //                create task to download user submitted image from firebase storage
            let task = URLSession.shared.dataTask(with: imageData.imageURL) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("Failed to download image:", error?.localizedDescription ?? "Unknown error")
                    return
                }
                // Create UIImage from downloaded data
                if let image = UIImage(data: data) {
                    // Set the image to the imageView on the main thread
                    DispatchQueue.main.async {
                        videoCell.imageDisplayView.image = image
                    }
                } else {
                    print("Failed to create image from downloaded data")
                }
            }
            task.resume()
            
            return videoCell
        }
        return UITableViewCell()
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // Check if the section is the one where editing is allowed (only when user does upload an image and only on their submission)
        if indexPath.section == SECTION_UPLOAD {
            guard UserDefaults.standard.dictionary(forKey: "QOTDUserImage") != nil else {       //if QOTDUserImage doesnt exist, user has not submitted an image, do not allow edit
                return .none
            }
            return .delete // Allow deletion
        } else {
            return .none // Disable editing for other sections
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
//            remove user submission from firestore
            database?.deleteUserQOTDFromFirestore { error in
                if let error = error {
                    print("Error deleting user SOTD from Firestore: \(error.localizedDescription)")
                } else {
                    print("User SOTD deleted successfully from Firestore")
                    UserDefaults.standard.removeObject(forKey: "QOTDUserImage")     //remove from user defaults
                    self.database?.decreaseQOTDStreak()         //decrease their submission count
                    self.pickingimage = false                   //allow users to interact with upload button again
                }
            }
            
            self.database?.fetchImagesFromFirestore() { [weak self] fetchedImages in
                // Assign fetched images to self.images, then reloads the table
                self?.images = fetchedImages
                DispatchQueue.main.async {
                    self?.qotdTable.reloadData()
                }
            }
            
            
        }
    }
}
