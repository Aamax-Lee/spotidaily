//
//  SOTDTodayViewController.swift
//  musictime
//
//  Created by Aamax Lee on 26/4/2024.
//

import UIKit
import FirebaseStorage

//if the SOTD tab is opened for the first time in the day after the SOTD has been reseted:
//direct users to this page that shows today's SOTD
//This page is only shown once in the day.
class SOTDTodayViewController: UIViewController {
    let defaults = UserDefaults.standard
    
    private var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var SOTDImage: UIImageView!
    
    @IBOutlet weak var SOTDSong: UILabel!
    @IBOutlet weak var SOTDArtist: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        animation to fade in the page elements
        DispatchQueue.main.async {
            UIView.animate(withDuration: 2) {
                self.SOTDImage.alpha = 1.0
                self.SOTDSong.alpha = 1.0
                self.SOTDArtist.alpha = 1.0
            }
        }
        
//        sets page background
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0), UIColor.black.cgColor]
        
        view.layer.insertSublayer(layer, at: 0)
        
//        loading animation while SOTD image is being fetched
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = SOTDImage.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        fetchSOTDData()
    }
    
    
    func fetchSOTDData() {
//        start the loading animation
        activityIndicator.startAnimating()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
//        firestore function to obtain today's SOTD
        appDelegate?.databaseController?.getSOTDofTheDay {sotd in
            if let sotd = sotd {
                
                self.SOTDSong.text = sotd.name
                self.SOTDArtist.text = sotd.artist
                
//                store today's SOTD information in userDefaults
                self.defaults.set(sotd.artist, forKey: "ArtistName")
                self.defaults.set(sotd.name, forKey: "SongName")
                self.defaults.set(sotd.image, forKey: "ImageURL")
                
                self.activityIndicator.stopAnimating()
                
//                SOTD image is stored in firebase storage for space efficiency
                let storageRef = Storage.storage().reference()
                let fileRef = storageRef.child(sotd.image!)
                fileRef.getData(maxSize: 5 * 1024 * 1024) {
                    data, error in
                    
                    if error == nil && data != nil {
//                        image exists and no errors found, set image element to sotd image
                        DispatchQueue.main.async {
                            self.SOTDImage.image = UIImage(data: data!)
                        }
                    } else {
                        print(error!)
                    }
                }
                
                
            }
            
        }
    }
        
            
//            ready button hthat allows user to dismiss page
    @IBAction func readyButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
        
    }


