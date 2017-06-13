//
//  RiderViewController.swift
//  UberClone
//
//  Created by Maria on 6/4/17.
//  Copyright © 2017 Maria Notohusodo. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager: CLLocationManager!
    var lat: CLLocationDegrees = 40
    var lon: CLLocationDegrees = -30
    var riderRequestActive = false
    var driverOnTheWay = false
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callUberButton: UIButton!
    @IBAction func callUber(_ sender: Any) {
        
        if riderRequestActive == false {
            let riderRequest = PFObject.init(className: "riderRequest")
            riderRequest["username"] = PFUser.current()?.username
            riderRequest["location"] = PFGeoPoint.init(latitude: lat, longitude: lon)
            
            riderRequest.saveInBackground(block: {[weak self](success, error) -> Void in
                if (success == true) {
                    self?.callUberButton.setTitle("Cancel Uber", for: .normal)
                } else {
                    let alert = UIAlertController(title: "Could not call Uber", message: "Please try again", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
                } as PFBooleanResultBlock )
            riderRequestActive = true
            
        } else {
            self.callUberButton.setTitle("Call an Uber", for: .normal)
            riderRequestActive = false
            let query = PFQuery.init(className: "riderRequest")
            query.whereKey("username", equalTo: PFUser.current()!.username!)
            query.findObjectsInBackground(block: { (objects, error) -> Void in
                if error == nil {
                    print("Successfully retrieved \(objects!.count) scores.")
                    if let objects = objects as [PFObject]?{
                        for object in objects {
                            object.deleteInBackground()
                        }
                    }  
                } else {
                    print(error!)
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutRider" {
            locationManager.stopUpdatingLocation()
            PFUser.logOut()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocationCoordinate2D = manager.location!.coordinate
        lat = location.latitude
        lon = location.longitude
        
        let query = PFQuery.init(className: "riderRequest")
        query.whereKey("username", equalTo: PFUser.current()!.username!)
        query.findObjectsInBackground(block: { (objects, error) -> Void in
            if error == nil {
                if let objects = objects as [PFObject]?{
                    
                    for object in objects {
                        if let driverUsername = object["driverResponded"] {
                            let query = PFQuery.init(className: "driverLocation")
                            query.whereKey("username", equalTo: driverUsername)
                            query.findObjectsInBackground(block: { (objects, error) -> Void in
                                if error == nil {
                                    if let objects = objects as [PFObject]?{                                     
                                        for object in objects {
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                
                                                let driverCLLOcation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                let distanceMeters = userCLLocation.distance(from: driverCLLOcation)/1000
                                                let rounded = Double(round(distanceMeters * 10)/10)
                                                self.callUberButton.setTitle("Driver is \(rounded) km away", for: .normal)
                                                self.driverOnTheWay = true
                                                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                                let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.005
                                                let lonDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.005
                                                let region = MKCoordinateRegion.init(center: center, span: MKCoordinateSpan.init(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                                self.map.setRegion(region, animated: true)
                                                self.map.removeAnnotations(self.map.annotations)
                                                var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                var objectAnnotation = MKPointAnnotation.init()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Your location"
                                                self.map.addAnnotation(objectAnnotation)
                                                pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                objectAnnotation = MKPointAnnotation.init()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Driver Location"
                                                self.map.addAnnotation(objectAnnotation)
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            }
        })
        if (driverOnTheWay == false) {
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion.init(center: center, span: MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01))
            map.setRegion(region, animated: true)
            map.removeAnnotations(map.annotations)
            let pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            let objectAnnotation = MKPointAnnotation.init()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Your location"
            map.addAnnotation(objectAnnotation)
        }
    }
}
