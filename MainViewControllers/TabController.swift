//
//  TabController.swift
//  musictime
//
//  Created by Aamax Lee on 25/4/2024.
//

import UIKit

//main tab controller to display the four sections of the app: SOTD, QOTD, events and profile page
class TabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProfile()  // Fetch user profile when the view loads
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
          
    }
//    fetch the user's profile information
    private func fetchProfile() {
        APICaller.shared.getCurrentUserProfile {
            [weak self] result in
            DispatchQueue.main.sync {
                switch result {
                case .success(let model):
                    print("success")
                    self?.updateUserId(with: model)
                case .failure(let error):
                    print("failure in fetchProfile: ", error.localizedDescription)
                    self?.failedToGetProfile()
                }
            }
        }
    }
    
//    Updates the user ID in the database with the provided model
    private func updateUserId(with model: UserProfile) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let userImageURL = model.images.first?.url ?? "https://example.com/placeholder_image.jpg"
        appDelegate?.databaseController?.storeSpotifyUserID(userID: model.id, email: model.email, name: model.display_name, userImage: userImageURL)
    }
    
//    helper function to display error message when unable to fetch user profile
    private func failedToGetProfile() {
        let label = UILabel(frame: .zero)
        label.text = "Failed to load user profile"
        label.sizeToFit()
        view.addSubview(label)
        label.center = view.center
    }
    

}
