//
//  LocationsOnMapViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import MapKit

class LocationsOnMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.mapType = .Standard
        }
    }
    
    func post() {
        print("post MAP")
    }
    
    func refresh() {
        print("reresh MAP")
        
        StudentPosts.clearPosts()
        
        Client.retrieveStudentInformation { (success, error, results) in
            if error != nil {
                self.displayLoginErrorAlert("Error", message: error!, handler: nil)
            } else if let results = results {
                StudentPosts.generatePostsFromData(results)
                self.createAndAddAnnotations()
            }
        }
    }
    
    func createAndAddAnnotations() {
        if !StudentPosts.sharedInstance.posts.isEmpty {
            print("not empty")
            var annotationsToAdd = [MKPointAnnotation]()
            
            for studentInfo in StudentPosts.sharedInstance.posts {
                
                let latitude = CLLocationDegrees(Double(studentInfo.latitude))
                let longitude = CLLocationDegrees(Double(studentInfo.longitude))
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                // Here we create the annotation and set its coordiate, title, and subtitle properties
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "\(studentInfo.firstName) \(studentInfo.lastName)"
                annotation.subtitle = studentInfo.mediaURL
                
                // Finally we place the annotation in an array of annotations.
                annotationsToAdd.append(annotation)
            }
            
            // When the array is complete, we add the annotations to the map.
            mapView.addAnnotations(annotationsToAdd)
        }
    }
    
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
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
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    }

}
