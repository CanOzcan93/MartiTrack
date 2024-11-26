//
//  TracingManager.swift
//  MartiTrack
//
//  Created by Can Özcan on 20.11.2024.
//

import MapKit

class TracingManager: CLLocationManager {
    
    static let shared = TracingManager()

    var lastLocation: CLLocation? {
        get {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: UserDefaults.standard.data(forKey: "lastLocation") ?? Data())
        }
    }
    
    var isTracing: Bool {
        get {
            if let value = UserDefaults.standard.value(forKey: "isTracing") as? Bool {
                return value
            } else {
                UserDefaults.standard.set(true, forKey: "isTracing")
                return true
            }
            
        } set {
            return UserDefaults.standard.set(newValue, forKey: "isTracing")
        }
    }
    
    func config() {
        delegate = self
        desiredAccuracy = kCLLocationAccuracyBest
        allowsBackgroundLocationUpdates = true
        requestWhenInUseAuthorization()
        if isTracing {
            startUpdatingLocation()
        } else {
            stopUpdatingLocation()
        }
        
    }
    
}

extension TracingManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tracingManagerDidUpdateLocations"), object: nil, userInfo: ["locations": locations])
        if let location = locations.last, let data = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "lastLocation")
        }
        
    }

}
