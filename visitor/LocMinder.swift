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

// be sure to add background capability for location tracking (not needed for visitEvent)
// be sure to add necessary priv strings in Info.Plist

// nb, visits mode can run in parallel if calling start and stop updates

enum LocationTechnique:String {
    
    case eachUpdate // supported technique
    case deferredUpdate //supported technique
    case visitEvent // supported technique
    
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
        let dat = "\(date)".split(separator: "+")
        let dis = dat[0]
        return "(\(lat),\(lon))\n\(dis)"
    }
    
}

class LocMinder:NSObject {
    
    var locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    var completion:((String)->())!
    var locationUpdateCount = 0
    var visitsUpdateCount = 0
    var mode : LocationTechnique = .eachUpdate
    
    
    func startWhenInUse(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        switch mode {
        case .visitEvent: break
        default:    locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        }
    }
    
    
    func startAlways(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        locationManager.requestAlwaysAuthorization()
        switch mode {
        case .visitEvent: break
        default:     locationManager.startUpdatingLocation()
        }
    }
    
    
   
    init(_ mode: LocationTechnique, completion:@escaping (String)->() ) {
        super.init()
        
        self.mode = mode
        startLocation = nil
        self.completion = completion
        
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .other
        locationManager.distanceFilter = 0.0
        locationManager.delegate = self
        
        switch mode  {
        case .visitEvent:
            if CLLocationManager.significantLocationChangeMonitoringAvailable()  {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startMonitoringVisits()
            } else {
                // if we cant use deferred updates, lower the accuracy
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                print( "fallback .significantLocationChangeMonitoring Not Available")
            }
        case .eachUpdate:
             locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        case .deferredUpdate:
            if  CLLocationManager.deferredLocationUpdatesAvailable() {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest // necessary for deferred
                locationManager.distanceFilter = tenMeters
                locationManager.allowDeferredLocationUpdates(untilTraveled:deferUntilTraveled, timeout: deferTimeout)
            } else {
                // if we cant use deferred updates, lower the accuracy
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                print( "fallback .deferredLocationUpdates Not Available")
            }
      
        }
        print("Starting location manager in \(mode) mode")
    }
       
 
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension LocMinder:CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {

        
        visitsUpdateCount += 1
        let lat = visit.coordinate.latitude
        let lon = visit.coordinate.longitude
        let hac =  visit.horizontalAccuracy
        let arrive = visit.arrivalDate
        let depart = visit.departureDate
        
        
        let llc = LastKnownLocation(lat: lat, lon: lon, date: Date())
        LastKnownLocation.savetoUserDefaults(l: llc)
        
        let latitudetext = String(format: "%.4f",lat)
        let longitudetext = String(format: "%.4f",lon)
        let hAccuracytext = String(format: "%.4f",hac )
        
        let str =
            ("(\(latitudetext),\(longitudetext))\n\(hAccuracytext),\n\(visitsUpdateCount),\(mode)\n\(arrive),\(depart)")
        
        completion(str)
        print(str)
        
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        // if running in deffered mode we might get a series of intermediate locations, just take the last
        
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        locationUpdateCount += 1
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        let latitudetext = String(format: "%.4f", latestLocation.coordinate.latitude)
        let longitudetext = String(format: "%.4f", latestLocation.coordinate.longitude)
        let hAccuracytext = String(format: "%.4f",latestLocation.horizontalAccuracy)
        let altitudetext = String(format: "%.4f", latestLocation.altitude)
        let vAccuracytext = String(format: "%.4f", latestLocation.verticalAccuracy)
         let distanceBetween: CLLocationDistance =  latestLocation.distance(from: startLocation)
        let distancetext = String(format: "%.2f", distanceBetween)
        
        let str =
            ("(\(latitudetext),\(longitudetext))\n\(hAccuracytext),\(locationUpdateCount),\(mode)\n\(altitudetext),\(vAccuracytext),\(distancetext)")
        
        let lat = latestLocation.coordinate.latitude
        let lon = latestLocation.coordinate.longitude
        let llc = LastKnownLocation(lat: lat, lon: lon, date: Date())
        LastKnownLocation.savetoUserDefaults(l: llc)
        completion(str)
    }
 
    
    // for deferrred mode
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        print("didFinishDeferredUpdatesWithError  \(String(describing: error))")
        
        manager.allowDeferredLocationUpdates(untilTraveled:deferUntilTraveled, timeout: deferTimeout)
    }
}
