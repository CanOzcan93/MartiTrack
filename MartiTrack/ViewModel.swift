//
//  ViewModel.swift
//  MartiTrack
//
//  Created by Can Özcan on 26.11.2024.
//

import Foundation
import MapKit

protocol ViewModelDelegate: AnyObject {
    func locationsUpdated(with newLocations: [CLLocation])
}

class ViewModel {
    
    weak var delegate: ViewModelDelegate?
    
    var trackedLocations: [CLLocation] = []
    
    func fetchLocations() {
        trackedLocations = (try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CLLocation.self, from: UserDefaults.standard.data(forKey: "trackedLocations") ?? Data())) ?? []
        delegate?.locationsUpdated(with: trackedLocations)
    }
    
    func updateLocations(with locations: [CLLocation]) {
        
        let newLocations: [CLLocation] = locations.filter({ trackedLocations.last?.distance(from: $0) ?? 101 > 100 })
        trackedLocations.append(contentsOf: newLocations)
        if let encodedLocations = try? NSKeyedArchiver.archivedData(withRootObject: trackedLocations, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedLocations, forKey: "trackedLocations")
        }
        
        delegate?.locationsUpdated(with: newLocations)
        
    }
    
    func deleteAllLocations() {
        trackedLocations.removeAll()
        UserDefaults.standard.removeObject(forKey: "trackedLocations")
    }
    
    func getAddress(location: CLLocation, completion: @escaping (String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            var addressString : String = ""
            if let placemark = placemarks?.first {
                if placemark.isoCountryCode == "TW" /*Address Format in Chinese*/ {
                    if let country = placemark.country {
                        addressString = country
                    }
                    if let subAdministrativeArea = placemark.subAdministrativeArea {
                        addressString = addressString + subAdministrativeArea + ", "
                    }
                    if let postalCode = placemark.postalCode {
                        addressString = addressString + postalCode + " "
                    }
                    if let locality = placemark.locality {
                        addressString = addressString + locality
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressString = addressString + thoroughfare
                    }
                    if let subThoroughfare = placemark.subThoroughfare {
                        addressString = addressString + subThoroughfare
                    }
                } else {
                    if let subThoroughfare = placemark.subThoroughfare {
                        addressString = subThoroughfare + " "
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressString = addressString + thoroughfare + ", "
                    }
                    if let postalCode = placemark.postalCode {
                        addressString = addressString + postalCode + " "
                    }
                    if let locality = placemark.locality {
                        addressString = addressString + locality + ", "
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        addressString = addressString + administrativeArea + " "
                    }
                    if let country = placemark.country {
                        addressString = addressString + country
                    }
                }
            }
            completion(addressString)
        }
    }
    
}
