//
//  SearchViewController.swift
//  musictime
//
//  Created by Aamax Lee on 13/5/2024.
//

import UIKit

class SearchViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate {
     
    var imageURL: URL?      //user submitted image stored here
    
    let searchController: UISearchController = {        //view controller that displays search bar along with search results
        let vc = UISearchController(searchResultsController: SearchResultsViewController())
        vc.searchBar.placeholder = "Search for Songs here"
        vc.searchBar.searchBarStyle = .minimal
        vc.definesPresentationContext = true
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = self.searchController
    }
    
    func updateSearchResults(for searchController: UISearchController) {        //to conform to delegate
         
    }
    
//    called when search bar is pressed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        initialise search results view controller to display results
        guard let resultsController = searchController.searchResultsController as? SearchResultsViewController,
            let query = searchBar.text,     //user typed query
        !query.trimmingCharacters(in: .whitespaces).isEmpty else {      //ensures query isn't blank
            return
        }
        
        // Assigning delegate and image URL to the search results view controller
        resultsController.delegate = self
        resultsController.imageURL = self.imageURL  //so uploading to firebase function can be called with user uploaded image in parameter
        
        // Making API call to spotify API to fetch search results
        APICaller.shared.search(with: query) { result in
            DispatchQueue.main.sync {
                switch result {
                case .success(let results):
                    resultsController.update(with: results)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

        }
     
        
        
        
    }
    
     
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//        if SearchResultsViewController.b == true && segue.identifier == "returnToQOTDSegue" {
////            let destination = segue.destination
//            
//        
//        }
//    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check if the segue is for returning to the QOTD (Quote of the Day) view
            if segue.identifier == "returnToQOTDSegue",
               let selectedIndex = sender as? Int,
               let tabBarController = segue.destination as? UITabBarController {
                // Set the selected tab index
                tabBarController.selectedIndex = selectedIndex
            }
        }
    

}

// Extension to handle delegate methods of SearchResultsViewController
extension SearchViewController: SearchResultsViewControllerDelegate {
    // Method to present search results
    func showResult(_ controller: UIViewController) {
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // Method called when a search result is selected
    func didSelectResult(track: TrackObject) {
        let selectedIndex = 1
        performSegue(withIdentifier: "returnToQOTDSegue", sender: selectedIndex)    
    }
}
