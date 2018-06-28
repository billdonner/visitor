//
//  LocMinder.swift
//  visitor
//
//  Created by bill donner on 6/28/18.
//  Copyright © 2018 bill donner. All rights reserved.
//

import Foundation
import CoreLocation

// get gps coordinate updates and post to UserDefaults
// (couples with HousecallMD) doctors app

// this version generates event on each CoreLocation update kCLLocationAccuracyNearestTenMeters

// be sure to add background capability for location tracking
// be sure to add necessary priv strings in Info.Plist

enum LocationTechnique {
    
    case eachUpdate // only supported technique at this moment
    case visitEvent
    
}
// MARK: Keep Last GPS Position and Time in UserDefaults
struct LastKnownLocation : Codable {
    let lat:CLLocationDegrees
    let lon:CLLocationDegrees
    let date: Date
}

// MARK: Encodable
extension LastKnownLocation {
    
    // since there is no real global area in this app just stash in userdefaults
    static func savetoUserDefaults(l:LastKnownLocation) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(l)
            // print(String(data: data, encoding: .utf8)!)
            let defaults =  UserDefaults.standard
            defaults.set(data,forKey: "loc")
        }
        catch {
            print ("could not save to userdefaults")
        }
    }
    
    // if no location has ever been obtained return nil and let the caller sort it out
    static func fetchfromUserDefaults() -> LastKnownLocation? {
        let defaults =  UserDefaults.standard
        if let loc = defaults.object (forKey: "loc") as? Data {
            let decoder = JSONDecoder()
            do {
                let stuff = try decoder.decode(LastKnownLocation.self, from:loc)
                return stuff
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func description() -> String {
        return "(\(lat),\(lon)) \(date)"
    }
    
}

class LocMinder:NSObject {
    
    var locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    var completion:((String)->())!
    var upcount = 0
    var mode : LocationTechnique = .eachUpdate
    
    
    func startWhenInUse(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
    }
    
    
    func startAlways(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    init(_ completion:@escaping (String)->() ) {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
        startLocation = nil
        self.completion = completion
    }
    
    func start(mode:LocationTechnique){
        // ask permissions
        
        self.mode = mode
        startWhenInUse(self)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension LocMinder:CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        upcount += 1
        
        
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        let latitudetext = String(format: "%.4f",
                                  latestLocation.coordinate.latitude)
        let longitudetext = String(format: "%.4f",
                                   latestLocation.coordinate.longitude)
        let hAccuracytext = String(format: "%.4f",
                                   latestLocation.horizontalAccuracy)
        let altitudetext = String(format: "%.4f",
                                  latestLocation.altitude)
        let vAccuracytext = String(format: "%.4f",
                                   latestLocation.verticalAccuracy)
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        let distanceBetween: CLLocationDistance =
            latestLocation.distance(from: startLocation)
        
        let distancetext = String(format: "%.2f", distanceBetween)
        
        let str =
            ("\(latitudetext),\(longitudetext),\(hAccuracytext),\(altitudetext),\(vAccuracytext),\(distancetext),\(upcount),\(mode)")
        
        let lat = latestLocation.coordinate.latitude
        let lon = latestLocation.coordinate.longitude
        let llc = LastKnownLocation(lat: lat, lon: lon, date: Date())
        LastKnownLocation.savetoUserDefaults(l: llc
        )
        completion(str)
    }
}
