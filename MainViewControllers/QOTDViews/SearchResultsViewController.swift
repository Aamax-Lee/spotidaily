//
//  SearchResultsViewController.swift
//  musictime
//
//  Created by Aamax Lee on 13/5/2024.
//

import UIKit

//Protocol to communicate back with the SearchViewController
protocol SearchResultsViewControllerDelegate: AnyObject {
    func showResult(_ controller: UIViewController)
    func didSelectResult(track: TrackObject)
}

//displays the results of the search through a table
class SearchResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var imageURL: URL?      //user submitted image
    var database: DatabaseProtocol?
    
    weak var delegate: SearchResultsViewControllerDelegate? //delegate for segueing back to the tab controller
    

    private var results: [SearchResult] = []        //list of results returned
    
    private let tableView: UITableView = {      //table view for results, with subtitle to display song name and artist
        let tableView = UITableView()
        tableView.register( SearchResultWithSubtitleTableViewCell.self, forCellReuseIdentifier: SearchResultWithSubtitleTableViewCell.identifier)
        tableView.register( UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isHidden = true
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate     // Get reference to the database controller from the app delegate
        
        self.database = appDelegate?.databaseController
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // Update the search results
    func update(with results: [SearchResult]) {
        self.results = results
        tableView.reloadData()
        tableView.isHidden = results.isEmpty    //if results are empty, hide the table and vice versa
    }
    
    //number of rows = number of results
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch results[indexPath.row] {
//            if result is a track, title is song name, subtitle is artist name, set imageURL as song image and use cell.configure to set the positions and dimensions of these elements
        case .track(let track):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultWithSubtitleTableViewCell.identifier, for: indexPath) as? SearchResultWithSubtitleTableViewCell else {
                return UITableViewCell()
            }
            
            let viewModel = SearchResultWithSubtitleTableViewCellViewModel(
                title: track.name,
                subtitle: track.artists.first?.name ?? "-",
                imageURL: URL(string: track.album.images.first?.url ?? ""))
            cell.configure(with: viewModel)
            return cell
            
            
//            for future implementation, to allow search results to include artist, album and playlist objects
        case .artist(model: let model):
            return UITableViewCell()
        case .album(model: let model):
            return UITableViewCell()
        case .playlist(model: let model):
            return UITableViewCell()
        }
        
        
         
    }
    
//    when a row is selected, upload to firebase along with user submitted image
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)    //unselect the row for visual purposes
        let result = results[indexPath.row]
        
        switch results[indexPath.row] {
            case .track(let track):
            if let imageURL = imageURL {
                    self.database?.uploadImageToFirebase(imageURL: imageURL, track: track) { success, error in      //upload user submitted image and selected track to firestore
                        if let error = error {
//                            upload unsuccessful
                            print("Error uploading image: \(error)")
                        } else if success {
                            // Upload successful
                            self.delegate?.didSelectResult(track: track)        //segue back to tab controller using delegate,
//                                                                                as we cant connect segue directly from ths view controller as it is not in the storyboard
                            self.database?.increaseQOTDStreak() //increase qotd streak to be displayed in profile view
                        }
                    }
                }
             
            default:
                break // for future implementation when we handle other objects such as artists, playlists and albums
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "returnToQOTDSegue" {
            // Check if the destination view controller is of the appropriate type
            if let destinationVC = segue.destination as? QOTDViewController {
                // Extract the track model from the sender
                if let track = sender as? TrackObject {
                    // Pass the track model to the destination view controller
                    destinationVC.track = track
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

}
