//
//  LocationsOnMapViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import MapKit
import SafariServices

class LocationsOnMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.mapType = .Standard
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .None
        }
    }
    
    var locationManager = CLLocationManager() {
        didSet {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    func post() {
        print("post MAP")
    }
    
    func refresh() {
        StudentPosts.clearPosts()
        Client.retrieveStudentInformation { (success, error, results) in
            if error != nil {
                self.displayLoginErrorAlert("Error", message: error!, handler: nil)
            } else if let results = results {
                StudentPosts.generatePostsFromData(results)
                dispatch_async(dispatch_get_main_queue(), {
                    self.createAndAddAnnotations()
                })
            }
        }
    }
    
    func createAndAddAnnotations() {
        if !StudentPosts.sharedInstance.posts.isEmpty {
            mapView.removeAnnotations(mapView.annotations)
            var annotationsToAdd = [PostAnnotation]()
            for studentInfo in StudentPosts.sharedInstance.posts {
                let annotation = PostAnnotation(studentInfo: studentInfo)
                annotationsToAdd.append(annotation)
            }
            mapView.addAnnotations(annotationsToAdd)
        }
    }
    
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        //prevents the user's location from being presented as a red pin, and enables the annoation for the user location to retain its default blue dot beacon
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("location") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "location")
            annotationView?.canShowCallout = true
            annotationView?.pinTintColor = MKPinAnnotationView.redPinColor()
            annotationView?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //the new safari view controller crashes when it is opened from a url that doesn't start with http or https; i used a version of the fix mentioned in the following stackoverflow page to address this: http://stackoverflow.com/questions/32864287/sfsafariviewcontroller-crashing-on-valid-nsurl
        if let subtitle = view.annotation?.subtitle {
            if let subtitle = subtitle {
                if let url = NSURL(string: subtitle) {
                    if ["http", "https"].contains(url.scheme.lowercaseString) {
                        let safariViewController = SFSafariViewController(URL: url)
                        presentViewController(safariViewController, animated: true, completion: nil)
                    } else {
                        let updatedURL = "http://" + subtitle
                        if let newNSURL = NSURL(string: updatedURL) {
                            let safariViewController = SFSafariViewController(URL: newNSURL)
                            presentViewController(safariViewController, animated: true, completion: nil)
                            //UIApplication.sharedApplication().openURL(newNSURL)
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        refresh()
    }

}
