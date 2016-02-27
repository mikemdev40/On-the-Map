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

    struct Constants {
        static let openPostViewSegue = "SegueFromMapToPost"
        static let latitudeDelta: CLLocationDegrees = 0.05
        static let longitudeDelta: CLLocationDegrees = 0.05
    }
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.mapType = .Standard
            mapView.userTrackingMode = .None
        }
    }
    
    var annotationToZoomTo: PostAnnotation?
    
    func post() {
        performSegueWithIdentifier(Constants.openPostViewSegue, sender: self)
    }
    
    func refresh() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        StudentPosts.clearPosts()
        Client.retrieveStudentInformation { (success, error, results) in
            dispatch_async(dispatch_get_main_queue(), {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if error != nil {
                    self.displayLoginErrorAlert("Error", message: error!, handler: nil)
                } else if let results = results {
                    StudentPosts.generatePostsFromData(results)
                    self.createAndAddAnnotations()
                }
                Client.didPostItem.0 = false
            })
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
            annotationToZoomTo = annotationsToAdd[0]
            mapView.addAnnotations(annotationsToAdd)
            
            if Client.didPostItem.0 {
                if let annotationToZoomTo = annotationToZoomTo {
                    let region = MKCoordinateRegion(center: annotationToZoomTo.coordinate, span: MKCoordinateSpan(latitudeDelta: Constants.latitudeDelta, longitudeDelta: Constants.longitudeDelta))
                    mapView.setRegion(region, animated: true)
                    mapView.selectAnnotation(annotationToZoomTo, animated: true)
                }
            }
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
            annotationView?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)  //the detail disclosure type seems to be the only type that enables "press ANYWHERE on the callout, including the whitespace to the left of the aactual right accessory view, in order to call the mapView:calloutAccessoryControlTapped: delegate method, and i can't figure out why! for example, if you change this button type to "contact add" instead then run, you have to tap the actual accessory icon (and ONLY the icon) to activate mapView:calloutAccessoryControlTapped:; tapping on the whitespace of the callout does NOT call the method!
        
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    //this delegate method gets invoked when whitespace of the callout is tapped (i.e. to the left of the "i" callout accessory button), in addition to the callout button iteself, but this is the case ONLY for the detail disclosure type of accessory button; for other button types, this methods gets invoked ONLY when the actual button is tapped (not sure why this exception exists)
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let subtitle = view.annotation?.subtitle {
            if let subtitle = subtitle {
                if let url = NSURL(string: subtitle) {
                    //the new safari view controller crashes when it is opened from a url that doesn't start with http or https; i used a version of the fix mentioned in the following stackoverflow page to address this: http://stackoverflow.com/questions/32864287/sfsafariviewcontroller-crashing-on-valid-nsurl
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if Client.didDeleteItem {
            refresh()
            Client.didDeleteItem = false
        }
        
        if Client.didPostItem.0 {
            refresh()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    }
}
