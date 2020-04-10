//
//  LocationManager.swift
//  EARS
//
//  Created by Wyatt Reed on 7/18/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import Reachability
import UserNotifications


class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var locTimerReady: Bool = true
    static var ithFile: Int = 1
    
    static var uploadSet: Bool = false
    var netState: String!
    
    lazy var gpsDataString = "GPS"

    private var notificationTimeFetchedResultsController: NSFetchedResultsController<SetupComplete>!
    
    
    /**
     Returns a Bool value indicating whether both:
     - location services are enabled on the device
     - app’s authorized for using location services.
     - returns: true or false
     */
    
    func locationEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled() && !AppDelegate.deactivated && CLLocationManager.authorizationStatus() == .authorizedAlways;
    }
    
    var notblocking =  false
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if (locationEnabled()) {
            
            storeLocation(manager, locations: locations)
            
        }
    }
    
    /**
     Store location data in shared DataStorageManager at specific timed intervals.
     - parameters:
     
         - manager: CLLocationManager: The object that you use to start and stop the delivery of location-related events to your app.
         - locations: [CLLocation]: The latitude, longitude, and course information reported by the system.
     */
    
    func storeLocation(_ manager: CLLocationManager, locations: [CLLocation]) {
        
        var tempLocations = locations
        tempLocations.sort { (loc1, loc2) -> Bool in
            return (loc1.timestamp) > (loc2.timestamp)
        }
        let dataStorage = DataStorage()

        for newLocation in tempLocations {
            
            let gpsProtoBuf = Research_GPSEvent.with {
                $0.timestamp = Int64(newLocation.timestamp.timeIntervalSince1970 * 1000)
                $0.lat = Double(newLocation.coordinate.latitude)
                $0.lon = Double(newLocation.coordinate.longitude)
            }

            //Write each location
            dataStorage.writeFileProto(dataType: self.gpsDataString, messageArray: [gpsProtoBuf])
        }

    }
    
    @objc func updateLocTimerStatus(){
        self.locTimerReady = true
    }
    
    /**
     Calls locationManager.startUpdatingLocation() with best location accuracy and no distance filter
     */
    func startLocationUpdates() {
        //print("startLocationUpdates")
        locationManager.delegate = self
        locationManager.activityType = .other
        //locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }
    /**
     Calls locationManager.stopUpdatingLocation() to disable location services.
     */
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    deinit {
        //NSLog("LocationManager deinit invoked.")
        
    }
    
    
}
