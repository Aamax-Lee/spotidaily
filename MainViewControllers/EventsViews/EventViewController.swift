import UIKit
import CoreLocation


//Protocol to handle button tap events in the EventsTableViewCell (for sending user to a separate view controlwle containing webview for purchasing tockets
protocol EventsTableViewCellDelegate: AnyObject {
    func didTapButton(in cell: EventsTableViewCell, url: String)
}

//UITableViewCell subclass for displaying event details
class EventsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imageEvent: UIImageView! //Image view displaying the event image
    weak var delegate: EventsTableViewCellDelegate? //delegate to handle the didtapbutton events
    
    @IBOutlet weak var dateEventlabel: UILabel! //label to display date of event
    @IBOutlet weak var nameEventlabel: UILabel! //label to display name of event
    
    @IBOutlet weak var urlButton: UIButton!     //button to direct user to event
    
    var ticketUrl: String?      //URL for purchasing tickets to the event
    
    func configureImage() {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupImageEventConstraints()
    }
    
//    Handles the press event on the URL button
    @IBAction func onUrlButtonPress(_ sender: Any) {
        
//        ensures purchase ticket url is valid before segueing to webview
        guard let ticketUrlString = ticketUrl, let _ = URL(string: ticketUrlString) else {
            let alert = UIAlertController(title: "Invalid URL", message: "The URL is not valid.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            return
        }
        delegate?.didTapButton(in: self, url: ticketUrl ?? "No url")    //delegate used to send ticketUrl to webview view controller so destination vc can access and display said url
        
    }
    
    func setupImageEventConstraints() {
    }
}

//View controller for displaying events near the user's location
class EventViewController: UIViewController, TicketmasterLocationDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, EventsTableViewCellDelegate {
    
//    Location manager for handling location updates
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var eventsTable: UITableView!    //Table view displaying the list of events
    
    var eventsResults:[Event] = []      //array of fetched events
    var currentPage = 0         //initialise current number of pages as 0, to be increased
    var isLoading = false       //Flag to indicate if data is currently being loaded
    
    var ticketWebViewUrl: String?       //string storing url to purchase ticket
    
    var previousLocation: CLLocation?   //Previous location to track significant changes
    let locationChangeThreshold: CLLocationDistance = 10000 // 100 km
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setup background color (gradient)
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0).cgColor, UIColor.black.cgColor]
        view.layer.insertSublayer(layer, at: 0)
        
        // Configure table view data source and delegate
        eventsTable.dataSource = self
        eventsTable.delegate = self
        
        // Configure location manager
        locationManager.delegate = self
//        ensures we have permission to access user location before proceding
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            TicketmasterLocationManager.shared.getCurrentLocation()
            TicketmasterLocationManager.shared.locationDelegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
//    Handles location updates when the location is successfully updated
    func didUpdateLocation(_ location: CLLocation) {
            guard let previousLocation = previousLocation else {
                // First time getting location, load events
                self.previousLocation = location
                loadEvents(near: location)
                return
            }
            
            let distance = location.distance(from: previousLocation)
            if distance > locationChangeThreshold {
                // Location changed significantly, clear the event list
                self.eventsResults.removeAll()
                self.currentPage = 0
                self.previousLocation = location
                DispatchQueue.main.async {
                    self.eventsTable.reloadData()
                }
                loadEvents(near: location)
            }
        }
    
//    Loads events near the specified location
    func loadEvents(near location: CLLocation) {
           guard !isLoading else { return }     //ensures we dont call loading when uneccesary
           isLoading = true
        
        guard let previousLocation = previousLocation else {
            // First time getting location, load events
            self.previousLocation = location
            loadEvents(near: location)
            return
        }
        
        let distance = location.distance(from: previousLocation)
        if distance > locationChangeThreshold {
            // Location changed significantly, clear the event list
            self.eventsResults.removeAll()
            self.currentPage = 0
            self.previousLocation = location
            DispatchQueue.main.async {
                self.eventsTable.reloadData()
            }
            loadEvents(near: location)
        } else {
            // Location change is not significant, load more events
            loadEvents(near: location)
        }
           
           TicketmasterAPICaller.shared.getEvents(near: location, page: currentPage) { result in
               switch result {
               case .success(let events):
                   self.eventsResults.append(contentsOf: events)
                   self.currentPage += 1
                   DispatchQueue.main.async {
                       self.eventsTable.reloadData()
                   }
               case .failure(let error):
                   print("Failed to get events near user: \(error)")
               }
               self.isLoading = false
           }
       }
     
//    if user scrolls to end of list, load more events
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offsetY = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let height = scrollView.frame.size.height
            
            if offsetY > contentHeight - height - 20 {
                if let location = locationManager.location {
                    loadEvents(near: location)
                }
            }
        }
    
//     helper function in case of failure
    func didFailWithError(_ error: Error) {
        print("Failed to get location: \(error)")
    }
    
//    number of rows in table = number of events retireved
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventsResults.count
    }
    
//    height of cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    
//    ifpurchase ticket button is pressed, segue to webview and set sender as self so we can  "send" the ticket url in prepare for segue
    func didTapButton(in cell: EventsTableViewCell, url: String) {
        self.ticketWebViewUrl = url
        performSegue(withIdentifier: "buyTicketSegue", sender: self)
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as? EventsTableViewCell else {
            return UITableViewCell()
        }
        
//        grab the first image in the list of images given for the event and display it as the event image
        if let firstImage = eventsResults[indexPath.row].images.first, let imageUrl = URL(string: firstImage.url) {
            // Perform asynchronous image loading using URLSession
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                // Check for errors
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                guard let imageData = data else {
                    print("No image data received")
                    return
                }
                DispatchQueue.main.async {
                    if let image = UIImage(data: imageData) {
                        // Assign the image to the cell's imageView
                        cell.imageEvent.image = image
                    } else {
                        print("Failed to initialize UIImage from data")
                    }
                }
            }.resume()
        } else {
            print("No image available for the event")
        }
        
//        configure event name and date labels to retrieved data
        let url = eventsResults[indexPath.row].url
        let eventName = eventsResults[indexPath.row].name
        let eventDate = eventsResults[indexPath.row].dates.start.localDate
        
        cell.nameEventlabel.text = eventName
        cell.dateEventlabel.text = eventDate
        cell.ticketUrl = url
        
        cell.delegate = self
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "buyTicketSegue" {
               if let destinationVC = segue.destination as? WebViewViewController {
                   destinationVC.ticketWebViewUrl = self.ticketWebViewUrl       //  "send" the ticket url to webview view controller to be displayed
               }
           }
       }
     
    
}
