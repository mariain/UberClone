//
//  RequestViewController.swift
//  UberClone
//
//  Created by Maria on 6/9/17.
//  Copyright © 2017 Maria Notohusodo. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RequestViewController: UIViewController {
    var requestLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var requestUsername: String = ""
    
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func pickUpRider(_ sender: Any) {
        let query = PFQuery.init(className: "riderRequest")
        query.whereKey("username", equalTo: requestUsername)
        query.findObjectsInBackground(block: { (objects, error) -> Void in
            if error == nil {
                if let objects = objects as [PFObject]?{
                    for object in objects {
                        let query = PFQuery.init(className: "riderRequest")
                        query.getObjectInBackground(withId: object.objectId!) {
                            (object, error) -> Void in
                            if error != nil {} else if let object = object {
                                object["driverResponded"] = PFUser.current()!.username
                                object.saveInBackground()
                                let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                                CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) -> Void in
                                    if error != nil {} else {
                                        if placemarks!.count > 0 {
                                            let pm = placemarks![0]
                                            let mkPm = MKPlacemark(placemark: pm)
                                            let mapItem = MKMapItem(placemark: mkPm)
                                            mapItem.name = self.requestUsername
                                            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                                            mapItem.openInMaps(launchOptions: launchOptions)
                                        } else {
                                            print("Problem with the data received from geocoder")
                                        }  
                                    }
                                })
                                
                            }
                        }
                    }
                }
            } else {
                print(error!)
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let region = MKCoordinateRegion.init(center: requestLocation, span: MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: true)
        let objectAnnotation = MKPointAnnotation.init()
        objectAnnotation.coordinate = requestLocation
        objectAnnotation.title = requestUsername
        map.addAnnotation(objectAnnotation)
    }
}
