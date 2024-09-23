//
//  ImageTableViewCell.swift
//  musictime
//
//  Created by Aamax Lee on 14/5/2024.
//

import UIKit
import FirebaseStorage
import MobileCoreServices
import AVFoundation
import UIKit
import AVKit

//custom table view cell to display submitted iamge along with submitted song
class ImageTableViewCell: UITableViewCell {
    @IBOutlet weak var qotdButton: UIButton!    //upload button for user to uplaod their own submission
    var imageContainerView: UIView = UIView()   //container that stores uplaoded image
    var imageDisplayView: UIImageView = UIImageView()       //UIImageView for uploaded image
    
    var userImageString: String?        //string versions of image urls in cell
    var trackImageString: String?
    
    var usernameLabel: UILabel = UILabel()              //label for username
    var userImageView: UIImageView = UIImageView()      //UIImageView for user's account image
    
     var trackImageView: UIImageView = {        //UIImageView for song's image
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        
     var trackTitleLabel: UILabel = {           //label for song title
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    
     var trackArtistLabel: UILabel = {          //label for song artist name
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    
 
    func hideImage() {
        
        imageDisplayView.isHidden = true
        imageContainerView.isHidden = true
        qotdButton.isHidden = false
        usernameLabel.isHidden = true
    }
    
    func hideButton() {
        
        imageContainerView.isHidden = false
        qotdButton.isHidden = true
        usernameLabel.isHidden = false
    }
    
    //sets username label text to username
    func usernameLabelText(username: String){
        self.usernameLabel.text = username
    }
     
//    Initializes the cell with the specified style and reuse identifier
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            commonInit()
        }
        
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            commonInit()
        }
    
//      function that sets uploaded image using image URL string
    func loadImageFromURL() {
        guard let url = URL(string: userImageString ?? "https://i.scdn.co/image/ab67757000003b82065095ea826bd0af9b49b768") else {
            return
        }


        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print("Failed to load image from URL:", error?.localizedDescription ?? "Unknown error")
                return
            }
            print("Received data size:", data.count)
            DispatchQueue.main.async {
                // Set the downloaded image to the image view
                self?.userImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
//    function that sets song image using image URL string
    func loadTrackImageFromURL() {
        guard let url = URL(string: trackImageString ?? "https://i.scdn.co/image/ab67757000003b82065095ea826bd0af9b49b768") else {
            return
        }


        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print("Failed to load image from URL:", error?.localizedDescription ?? "Unknown error")
                return
            }
            print("Received data size:", data.count)
            DispatchQueue.main.async {
                // Set the downloaded image to the image view
                self?.trackImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }

    
     
//    Performs common initialization tasks for the cell, setting size and position of all elements in cell
    private func commonInit() {
//        adds image container view first, setting appropriate background color and dimensions
            contentView.addSubview(imageContainerView)
            imageContainerView.translatesAutoresizingMaskIntoConstraints = false
            imageContainerView.backgroundColor = .gray
            NSLayoutConstraint.activate([
                imageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                imageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                imageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                imageContainerView.heightAnchor.constraint(equalToConstant: 290)
            ])

            // Add imageDisplayView to the container view
            imageContainerView.addSubview(imageDisplayView)
            imageDisplayView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageDisplayView.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 45), //space for username at top
                imageDisplayView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 0),
                imageDisplayView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: 0),
                imageDisplayView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: -65)   //space for song info at bottom
            ])
            
            imageContainerView.layer.cornerRadius = 10
//          round the corners of the image container
            imageContainerView.layer.masksToBounds = true
//          This ensures that the content inside the container view respects the rounded corners

            // Add userImageView to cell's content view
            imageContainerView.addSubview(userImageView)
            userImageView.translatesAutoresizingMaskIntoConstraints = false
            userImageView.backgroundColor = .red
                NSLayoutConstraint.activate([
                    userImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 10),
                    userImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 20),
                    userImageView.widthAnchor.constraint(equalToConstant: 30),
                    userImageView.heightAnchor.constraint(equalToConstant: 30)
                ])
            
            // Make the userimage view round
            userImageView.layer.cornerRadius = 15 // Half of width/height to make it a circle
            userImageView.layer.masksToBounds = true

            // Add usernameLabel to cell's content view
            contentView.addSubview(usernameLabel)
            usernameLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                usernameLabel.topAnchor.constraint(equalTo: imageContainerView.topAnchor, constant: 15),
                usernameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 10),        //place to right of userimage
                usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
            ])

            usernameLabel.textColor = .white
        
//         Add songImageView to container view (place below imageDisplayView)
                imageContainerView.addSubview(trackImageView)
                trackImageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    trackImageView.topAnchor.constraint(equalTo: imageDisplayView.bottomAnchor, constant: 10),
                    trackImageView.leadingAnchor.constraint(equalTo: userImageView.leadingAnchor),
                    trackImageView.widthAnchor.constraint(equalToConstant: 45), // Adjust size as needed
                    trackImageView.heightAnchor.constraint(equalToConstant: 45) // Adjust size as needed
                ])
        
                // Add trackTitleLabel to container view (place to right of song image)
                imageContainerView.addSubview(trackTitleLabel)
                trackTitleLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    trackTitleLabel.topAnchor.constraint(equalTo: imageDisplayView.bottomAnchor, constant: 10),
                    trackTitleLabel.leadingAnchor.constraint(equalTo: trackImageView.leadingAnchor, constant: 60),
                    trackTitleLabel.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: -20)
                ])
        
                // Add trackArtistLabel to container view (place to right of song image and below song name)
                imageContainerView.addSubview(trackArtistLabel)
                trackArtistLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    trackArtistLabel.topAnchor.constraint(equalTo: trackTitleLabel.bottomAnchor, constant: 5),
                    trackArtistLabel.leadingAnchor.constraint(equalTo: trackTitleLabel.leadingAnchor),
                    trackArtistLabel.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor, constant: -20)
                ])
             
        }
}
