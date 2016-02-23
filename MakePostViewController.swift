//
//  MakePostViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/21/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MakePostViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate {

    struct Constants {
        static let latitudeDelta: CLLocationDegrees = 0.05
        static let longitudeDelta: CLLocationDegrees = 0.05
    }
    
    @IBOutlet weak var locationTextField: UITextField! {
        didSet {
            locationTextField.delegate = self
            locationTextField.autocorrectionType = .No
            locationTextField.enablesReturnKeyAutomatically = true
            locationTextField.clearButtonMode = .WhileEditing
            locationTextField.textAlignment = .Center
        }
    }
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.mapType = .Standard
            mapView.showsUserLocation = false
            mapView.userTrackingMode = .None
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    let blurView = UIVisualEffectView()
    
    //use of a lazily initialized variable, as an alternative to setting the properties of the location manager in the viewDidLoad; although both methods accomplish the same thing - a location manager with relevant properties set before it is used elsewhere - i chose to use a lazy property just for practice of another method
    lazy var locationManager: CLLocationManager = {
        let lazyLocationManager = CLLocationManager()
        lazyLocationManager.delegate = self
        lazyLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        return lazyLocationManager
    }()
    
    @IBAction func findOnTheMap(sender: UIButton) {
        if locationTextField.text!.isEmpty {
            displayErrorAlert("Empty location!", message: "Please enter a location.", handler: nil)
            locationTextField.resignFirstResponder()
        } else {
            getLocationFromEntry(locationTextField.text!)
            locationTextField.resignFirstResponder()
        }
    }
    
    @IBAction func useCurrentLocation(sender: UIButton) {
        
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .AuthorizedWhenInUse:
            displayBlurEffect(true)
            locationManager.requestLocation()
        case .AuthorizedAlways:
            displayBlurEffect(true)
            locationManager.requestLocation()
        default:
            displayErrorAlert("Location services disabled", message: "Please re-enable location services in Settings for this app to use this feature!", handler: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            displayBlurEffect(true)
            locationManager.requestLocation()
        }
    }
    
    func getLocationFromEntry(locationString: String) {
        let geocoder = CLGeocoder()
        
        displayBlurEffect(true)
        
        //note that it wasn't necessary to dispatch to main queue since the completion handler for the geocoder completes on the main thread, as per the documentation
        geocoder.geocodeAddressString(locationString) {[unowned self] (placemarkArray, error) in
            self.displayBlurEffect(false)
            if let error = error {
                self.displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
            } else if let placemarks = placemarkArray {
                let placemark = placemarks[0]
                self.placePinOnMap(placemark, originalString: locationString)
            }
        }
    }
    
    func placePinOnMap(placemark: CLPlacemark, originalString: String?) {
        if let location = placemark.location {
            let annotation = MKPointAnnotation()
            var placemarkComponents = [String]()
    
            annotation.coordinate = location.coordinate
            
            if let neighborhood = placemark.subLocality {
                placemarkComponents.append(neighborhood)
            }
            if let city = placemark.locality {
                placemarkComponents.append(city)
            }
            if let state = placemark.administrativeArea {
                placemarkComponents.append(state)
            }
            if let country = placemark.country {
                placemarkComponents.append(country)
            }
            
            let placemarkInfo = placemarkComponents.joinWithSeparator(", ")
            annotation.subtitle = placemarkInfo
            
            if originalString != nil {
                annotation.title = originalString
            } else {
                var titleString = [String]()
                if let city = placemark.locality {
                    titleString.append(city)
                }
                if let state = placemark.administrativeArea {
                    titleString.append(state)
                } else if let country = placemark.country {
                    titleString.append(country)
                }
                let titleInfo = titleString.joinWithSeparator(", ")
                annotation.title = titleInfo
            }
            
            mapView.addAnnotation(annotation)
            
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: Constants.latitudeDelta, longitudeDelta: Constants.longitudeDelta))
            mapView.setRegion(region, animated: true)
        }
    }
    
    func displayBlurEffect(enable: Bool) {
        if enable {
            mapView.addSubview(blurView)
            blurView.frame = mapView.bounds
            UIView.animateWithDuration(0.2) {
                self.blurView.effect = UIBlurEffect(style: .Light)
            }
            spinner.startAnimating()
        } else {
            blurView.removeFromSuperview()
            spinner.stopAnimating()
        }
    }
    
    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func displayErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation) { (placemarkArray, error) in
            self.displayBlurEffect(false)
            if let error = error {
                self.displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
            } else if let placemarks = placemarkArray {
                let placemark = placemarks[0]
                self.placePinOnMap(placemark, originalString: nil)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pin?.canShowCallout = true
            pin?.pinTintColor = MKPinAnnotationView.greenPinColor()
        }
        else {
            pin?.annotation = annotation
        }
        return pin
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Make a Post"
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
        navigationItem.leftBarButtonItem = cancelButton
    }
}
