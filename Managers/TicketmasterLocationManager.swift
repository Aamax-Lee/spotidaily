import Foundation
import CoreLocation

// Define a protocol for location updates
protocol TicketmasterLocationDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)  //Called when the location is successfully updated
    func didFailWithError(_ error: Error)       //Called when there is an error updating the location
}

//class responsible for managing location updates
final class TicketmasterLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = TicketmasterLocationManager()
    
    weak var locationDelegate: TicketmasterLocationDelegate?    //Delegate to receive location updates
    var locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func getCurrentLocation() {     //request user current location
        requestLocationAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //Called when the CLLocationManager updates the location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationDelegate?.didUpdateLocation(location)
        locationManager.stopUpdatingLocation()
    }
    
    //Called when the CLLocationManager fails to update the location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationDelegate?.didFailWithError(error)
    }
    
    //requests location authorization from the user
    func requestLocationAuthorization() {
            locationManager.requestWhenInUseAuthorization()
        }
}
