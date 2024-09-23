//
//  SOTDViewController.swift
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

//custom table view cell to display submitted videos
class VideoTableViewCell: UITableViewCell {
    @IBOutlet weak var sotdButton: UIButton!        //upload button for user to upload their own submission
    
    var videoContainerView: UIView = UIView()   //container that stores uploaded video
    var videoDisplayView: sotdVideoDisplayView      //UIImageView for uploaded video
    var usernameLabel: UILabel = UILabel()      //label for username text
    var userImageView: UIImageView = UIImageView()      //imageview for user image
    
    var userImageString: String?        //user image url as a string
    
    func hideVideo() {      //hide the video if user hasn't submitted a video
        videoDisplayView.isHidden = true
        videoContainerView.isHidden = true
        sotdButton.isHidden = false
        usernameLabel.isHidden = true
    }
    
    func hideButton() {     //hide the button if the user did submit a video
        videoDisplayView.isHidden = false
        videoContainerView.isHidden = false
        sotdButton.isHidden = true
        usernameLabel.isHidden = false
    }
    
    func usernameLabelText(username: String){       //set username label as the parameter string (username)
        self.usernameLabel.text = username
    }
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            self.videoDisplayView = sotdVideoDisplayView(frame: .zero)
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            loadImageFromURL()
            commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.videoDisplayView = sotdVideoDisplayView(frame: .zero)
            super.init(coder: aDecoder)
            loadImageFromURL()  //set userimage view as the userimage
            commonInit()
        }
    
//   set the userimage view as the userimagestring we stored
    func loadImageFromURL() {
        guard let url = URL(string: userImageString ?? "https://i.scdn.co/image/ab67757000003b82065095ea826bd0af9b49b768") else {   //placeholder image for if the user does not have an image
            return
        }


        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print("Failed to load image from URL:", error?.localizedDescription ?? "Unknown error")
                return
            }
            print("Received data size:", data.count)
            DispatchQueue.main.async {
                self?.userImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }

    
    
    private func commonInit() {
        // Add a container view to hold the sotdVideoDisplayView
        contentView.addSubview(videoContainerView)
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.backgroundColor = .gray
        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            videoContainerView.heightAnchor.constraint(equalToConstant: 270)  /*Adjust height as needed*/
        ])

        // Add videoDisplayView to the container view
        videoContainerView.addSubview(videoDisplayView)
        videoDisplayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoDisplayView.topAnchor.constraint(equalTo: videoContainerView.topAnchor, constant: 45),
            videoDisplayView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: 0),
            videoDisplayView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: 0),
            videoDisplayView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 0)
        ])
        
        videoContainerView.layer.cornerRadius = 10 // Adjust corner radius as needed
        videoContainerView.layer.masksToBounds = true // This ensures that the content inside the container view respects the rounded corners

        // Add userImageView to cell's content view
        videoContainerView.addSubview(userImageView)
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.backgroundColor = .red
            NSLayoutConstraint.activate([
                userImageView.topAnchor.constraint(equalTo: videoContainerView.topAnchor, constant: 10),
                userImageView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: 20),
                userImageView.widthAnchor.constraint(equalToConstant: 30),
                userImageView.heightAnchor.constraint(equalToConstant: 30)
            ])
        
        // Make the image view round
        userImageView.layer.cornerRadius = 15 // Half of width/height to make it a circle
        userImageView.layer.masksToBounds = true

        // Add usernameLabel to cell's content view
        contentView.addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: videoContainerView.topAnchor, constant: 15), 
            usernameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 10),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])

        usernameLabel.textColor = .white
    }

}

/*
 The `SOTDViewController` is responsible for displaying the Song of the Day (SOTD) and managing user interactions with the SOTD and video uploads.
 It handles fetching vidoes from Firestore, displaying them in a table view, and allowing users to upload their own videos.
 */
class SOTDViewController: UIViewController, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate {
    
    let imagePicker = UIImagePickerController() //image picker class that we can use to pick videos from user's gallery
    var videoURL: URL?      //url for the user submitted video
    let defaults = UserDefaults.standard        //user defaults
    let videoDisplayView = sotdVideoDisplayView()
    var database: DatabaseProtocol?
    var pickingvideo = false        //checker variable to ensure button stops working after user uploads a video
    
    var videos: [(userName: String, videoURL: URL, userImage: String)] = [] //    array of uploaded videos from users
    
    private let refreshControl = UIRefreshControl()     //allows us to refresh the table on drag down
    
    let SECTION_UPLOAD = 0
    let SECTION_VIDEOS = 1
    
    
    @IBOutlet weak var sotdArtist: UILabel!
    @IBOutlet weak var sotdSong: UILabel!
    @IBOutlet weak var sotdImage: UIImageView!
    @IBOutlet weak var sotdTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        self.database = appDelegate?.databaseController
        
        imagePicker.delegate = self
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0), UIColor.black.cgColor]
         
        
        view.layer.insertSublayer(layer, at: 0)
        sotdTable.dataSource = self
        sotdTable.delegate = self
    }
    

    @objc private func refreshData(_ sender: Any) { //reload the table on drag down
        self.sotdTable.reloadData()
        refreshControl.endRefreshing()
        }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.database?.fetchVideosFromFirestore() { [weak self] fetchedVideos in
            // Assign fetched videos to self.videos, then reloads the table
            self?.videos = fetchedVideos
            DispatchQueue.main.async {
                self?.sotdTable.reloadData()
            }
        }
        
        sotdTable.refreshControl = refreshControl
                
        // Set up the refresh control action
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
                
//        get song of the day, with respective name artist and image
        self.database?.getSOTDofTheDay {sotd in
            if let sotd = sotd {
                self.defaults.set(sotd.artist, forKey: "ArtistName")
                self.defaults.set(sotd.name, forKey: "SongName")
                self.defaults.set(sotd.image, forKey: "ImageURL")
            }
            
            let artistName = self.defaults.string(forKey: "ArtistName")
            let songName = self.defaults.string(forKey: "SongName")
            let imageURL = self.defaults.string(forKey: "ImageURL")
            
            self.sotdSong.text = songName
            self.sotdArtist.text = artistName
            
            let storageRef = Storage.storage().reference()  //stored the song image in firebase storage (for space efficiency), so retreive from firebase storage
            let fileRef = storageRef.child(imageURL!)
            fileRef.getData(maxSize: 5 * 1024 * 1024) { [self]
                data, error in
                
                if error == nil && data != nil {
                    if let resizedImage = resizeImage(UIImage(data: data!)!, targetSize: CGSize(width: 89, height: 89)) {
                        DispatchQueue.main.async {
                            self.sotdImage.image = resizedImage
                        }
                    } else {
                        print(error as Any)
                    }
                }
            }
        }
        //        redirect the user to the screen that displays today's sotd if required
        redirectIfNeeded()
    }
    
//    to resize the image if too large
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func redirectIfNeeded() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Check if it's after 12 PM Australian time
//         let australiaTimeZone = TimeZone(identifier: "Australia/Sydney")!
        let australiaCalendar = Calendar(identifier: .gregorian)
        let australiaDate = australiaCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate)!
        
        if currentDate > australiaDate {
            // Check if the user has been redirected today
            let lastRedirectDate = UserDefaults.standard.value(forKey: "LastRedirectDate") as? Date ?? Date.distantPast
            let lastRedirectDay = calendar.startOfDay(for: lastRedirectDate)
            let currentDay = calendar.startOfDay(for: currentDate)
            
            if currentDay > lastRedirectDay {
                // Redirect the user to the new view controller
                UserDefaults.standard.set(currentDate, forKey: "LastRedirectDate")
                performSegue(withIdentifier: "SOTDTodayVCSegue", sender: nil)
            } else {
//                do nothing
            }
        }
    }
    
    
    //     if user presses upload button, show alert with option to choose from gallery or cancel action
    @IBAction func sotdButtonPress(_ sender: Any) {
        if self.pickingvideo {      //ensures button isn't press multiple times
            return
        } else {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let uploadAction = UIAlertAction(title: "Photo & Video Lbrary", style: .default) { _ in      //first option in alert, calls pickPictureFromGallery function on press
                self.pickVideoFromGallery()
            }
            
            alertController.addAction(uploadAction)
            
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)  //second option in alert, cancels action
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    func pickVideoFromGallery() {
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [UTType.movie.identifier as String]    //type of media as video
        present(imagePicker, animated: true, completion: nil)       //present the gallery picker vc
    }
    
    
//    helper show alert function
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
//    after user picks a video, upload the video to firebase storage and store a refrence to the storage in firestore
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.pickingvideo = true
        if let mediaType = info[.mediaType] as? String {
            if mediaType == UTType.movie.identifier as String {
                if let url = info[.mediaURL] as? URL {
                    videoURL = url
                    
                    self.database?.uploadVideoToFirebase(videoURL: videoURL!) { success, error in
                        if let error = error {
                            print("Error uploading video: \(error)")
                            self.showAlert(title: "Error", message: "Error uploading video")
                        } else if success {
                            // Upload successful
                             
                            self.database?.increaseSOTDStreak()     //increase the upload streak
 
                            self.database?.fetchVideosFromFirestore() { [weak self] fetchedVideos in
                                // Assign fetched videos to self.videos, then reloads the table
                                self?.videos = fetchedVideos
                                DispatchQueue.main.async {
                                    self?.sotdTable.reloadData()
                                }
                            }
                             
                        } else {
                            // Upload failed
                            self.showAlert(title: "Error", message: "Failure to upload video.")
                            print("Failed to upload video.")
                        }
                    }
                }
            }
        }
         
        dismiss(animated: true, completion: nil)
    }
    
    
//    original function to show user submitted video if exists, "depreciated" and not in use anymore
    func showVideoDisplayView() {
        self.database?.checkUserSubmittedVideoExists() { success, userName, videoRef in
            if success {
                self.videoDisplayView.frame = CGRect(x: 50, y: 50, width: 200, height: 200)
                self.videoDisplayView.configure(with: videoRef!)
                
                self.view.addSubview(self.videoDisplayView)
            }
        }
    }
    
     
//    protocol function, if cancel picking video then dismiss the gallery view controller
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         if indexPath.section == SECTION_UPLOAD {       //if user did not submit a video, set height as 80 to only fit the button, else set same height as other cells that display the videos
             guard let videoInfo = UserDefaults.standard.dictionary(forKey: "SOTDuserVideo"),
                   let _ = videoInfo["userName"] as? String,
                   let videoURLString = videoInfo["videoURL"] as? String,
                   let _ = URL(string: videoURLString) else {
                 return 80
             }
             return 285
         } else if indexPath.section == SECTION_VIDEOS {    //other user submission cells
             return 285
         }
         return 25
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_UPLOAD {      //user submission section only has 1 cell
            return 1
        } else
        if section == SECTION_VIDEOS {      //other user submitted videos
            return videos.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         
        if indexPath.section == SECTION_UPLOAD {        //for user submission cell
            guard let videoInfo = UserDefaults.standard.dictionary(forKey: "SOTDuserVideo"),
                  let userName = videoInfo["userName"] as? String,
                  let videoURLString = videoInfo["videoURL"] as? String,
                  let userImageString = videoInfo["userImage"] as? String,
                  let videoURL = URL(string: videoURLString) else {     //checks if user submitted a video, if not set to "uploadcell" where only the button is shown
 
                guard let uploadCell = tableView.dequeueReusableCell(withIdentifier: "UploadCell", for: indexPath) as? VideoTableViewCell else {
                    return UITableViewCell()
                }
                uploadCell.hideVideo()
                uploadCell.sotdButton.isHidden = false  //show button for user to uplaod video
                uploadCell.usernameLabel.isHidden = true
                
                return uploadCell
            }
            
//            code below for instance when user did submit a video
            guard let videoCell = tableView.dequeueReusableCell(withIdentifier: "UploadCell", for: indexPath) as? VideoTableViewCell else {
                return UITableViewCell()
            }
//            hide the uplaod button and show all the necessary information (video, userimage, username)
            videoCell.hideButton()
            videoCell.videoDisplayView.isHidden = false
            videoCell.usernameLabel.isHidden = false
            videoCell.usernameLabelText(username: userName)
            videoCell.userImageString = userImageString
            videoCell.loadImageFromURL()
            
            videoCell.videoDisplayView.configure(with: videoURL)
             
            
            return videoCell
              
        } else
        if indexPath.section == SECTION_VIDEOS {    //other user submissions
            guard let videoCell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as? VideoTableViewCell else {
                return UITableViewCell()
            }
            
            
            let videoData = videos[indexPath.row]
            videoCell.videoDisplayView.configure(with: videoData.videoURL)
            videoCell.usernameLabelText(username: videoData.userName)
            videoCell.userImageString = videoData.userImage
            videoCell.loadImageFromURL()
            
            return videoCell
        }
        return UITableViewCell()
    }
       
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            if indexPath.section == SECTION_UPLOAD {
                guard UserDefaults.standard.dictionary(forKey: "SOTDuserVideo") != nil else {   //if user did submit a video, then only allow deletion of their video
                    return .none
                }
                return .delete // Allow deletion for rows in section 1
            } else {
                return .none // Disable editing for other sections
            }
        }
         
    
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                database?.deleteUserSOTDFromFirestore { error in        //remove user submitted video from firestore
                    if let error = error {
                        print("Error deleting user SOTD from Firestore: \(error.localizedDescription)")
                    } else {
//                        User SOTD deleted successfully from Firestore
                        self.database?.decreaseSOTDStreak()
                        self.pickingvideo = false
                        UserDefaults.standard.removeObject(forKey: "SOTDuserVideo")
                    
                    
                        self.database?.fetchVideosFromFirestore() { [weak self] fetchedVideos in
                            // Assign fetched videos to self.videos, then reloads the table
                            self?.videos = fetchedVideos
                            DispatchQueue.main.async {
                                self?.sotdTable.reloadData()
                            }
                        }
                        
                        
                    }
                }
            }
        }
    
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    
 
