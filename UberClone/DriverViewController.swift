//
//  DriverViewController.swift
//  UberClone
//
//  Created by Maria on 6/9/17.
//  Copyright © 2017 Maria Notohusodo. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverViewController: UITableViewController, CLLocationManagerDelegate {
    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    var distances = [CLLocationDistance]()
    var locationManager: CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocationCoordinate2D = manager.location!.coordinate
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        var query = PFQuery.init(className: "driverLocation")
        query.whereKey("username", equalTo: PFUser.current()!.username!)
        query.findObjectsInBackground(block: { (objects, error) -> Void in
            if error == nil {
                if let objects = objects as [PFObject]? {
                    if objects.count > 0 {
                        for object in objects {
                            let query = PFQuery.init(className: "driverLocation")
                            query.getObjectInBackground(withId: object.objectId!) {
                                (object, error) -> Void in
                                if error != nil {
                                    print(error!)
                                } else if let object = object {
                                    object["driverLocation"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
                                    object.saveInBackground()
                                }
                            }
                        }} else {
                        
                        let driverLocation = PFObject(className:"driverLocation")
                        driverLocation["username"] = PFUser.current()?.username
                        driverLocation["driverLocation"] = PFGeoPoint(latitude:location.latitude, longitude:location.longitude)
                        driverLocation.saveInBackground()
                    }
                }
            } else {
                print(error!)
            }
        })
        
        query = PFQuery.init(className: "riderRequest")
        query.whereKey("location", nearGeoPoint:PFGeoPoint(latitude:location.latitude, longitude:location.longitude))
        query.limit = 10
        query.findObjectsInBackground(block: { (objects, error) -> Void in
            if error == nil {
                if let objects = objects as [PFObject]?{
                    self.usernames.removeAll()
                    self.locations.removeAll()
                    for object in objects {
                        
                        if object["driverResponded"] == nil {
                            if let username = object["username"] as? String {
                                self.usernames.append(username)
                            }
                            if let returnedLocation = object["location"] as? PFGeoPoint {
                                let requestLocation = CLLocationCoordinate2DMake(returnedLocation.latitude, returnedLocation.longitude)
                                self.locations.append(requestLocation)
                                let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                                let driverCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                let distance = driverCLLocation.distance(from: requestCLLocation)
                                self.distances.append(distance/1000)
                            }
                        }
                    }
                    self.tableView.reloadData()
                }
            } else {
                print(error!)
            }
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let distanceDouble = Double(distances[indexPath.row])
        let roundedDistance = Double(round(distanceDouble * 10)/10)
        cell.textLabel?.text = usernames[indexPath.row] + " - " + String(roundedDistance) + " km away"
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutDriver" {
            navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: false)
            locationManager.stopUpdatingLocation()
            PFUser.logOut()
        } else if segue.identifier == "showViewRequest" {
            if let destination = segue.destination as? RequestViewController {
                destination.requestLocation = locations[(tableView.indexPathForSelectedRow?.row)!]
                destination.requestUsername = usernames[(tableView.indexPathForSelectedRow?.row)!]
            }
        }
    }
}
