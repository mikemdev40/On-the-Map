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
    
    enum ViewToDisplay {
        case LocationSelectionView, URLtoShareView
    }
    
    @IBOutlet weak var locationTextField: UITextField! {
        didSet {
            setupButons(locationTextField)
        }
    }
    @IBOutlet weak var urlTextField: UITextField! {
        didSet {
            setupButons(urlTextField)
            urlTextField.tag = 10
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
    
    @IBOutlet weak var enterURLToShareView: UIView!
    @IBOutlet weak var whatIsYourLocationView: UIView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    let blurView = UIVisualEffectView()
    var saveLocationButton: UIBarButtonItem!
    var savePostButton: UIBarButtonItem!
    var trashButton: UIBarButtonItem!
    var flexSpace: UIBarButtonItem!
    var currentViewDisplayed: UIView?

    //use of a lazily initialized variable, as an alternative to setting the properties of the location manager in the viewDidLoad; although both methods accomplish the same thing - a location manager with relevant properties set before it is used elsewhere - i chose to use a lazy property just for practice of another method
    lazy var locationManager: CLLocationManager = {
        let lazyLocationManager = CLLocationManager()
        lazyLocationManager.delegate = self
        lazyLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        return lazyLocationManager
    }()
    
    @IBAction func findOnTheMap(sender: UIButton) {
        if locationTextField.text!.isEmpty {
            displayErrorAlert("Empty location", message: "Please enter a location.", handler: nil)
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
                self.hideSaveCancelToolbar(false)
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
            
            if placemarkComponents.count == 4 {
                placemarkComponents.removeLast()
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
                }
                if let country = placemark.country {
                    titleString.append(country)
                }
                if titleString.count == 3 {
                    titleString.removeLast()
                }
                let titleInfo = titleString.joinWithSeparator(", ")
                annotation.title = titleInfo
            }
            
            mapView.removeAnnotations(mapView.annotations)
            
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: Constants.latitudeDelta, longitudeDelta: Constants.longitudeDelta))
            mapView.setRegion(region, animated: true)
            
            mapView.addAnnotation(annotation)
            mapView.selectAnnotation(mapView.annotations[0], animated: true)
        }
    }
    
    func saveLocation() {
        swapViews(.URLtoShareView)
        hideSaveCancelToolbar(true)
    }
    
    func savePost() {
        
        guard let mediaURL = urlTextField.text else {
            displayErrorAlert("No URL", message: "Please enter a URL!", handler: nil)
            return
        }
        guard mapView.annotations.count > 0 else {
            displayErrorAlert("No Location", message: "No location to save.", handler: nil)
            return
        }
        
        let annotation = mapView.annotations[0]
        if let title = annotation.title, let mapString = title  {
            Client.makePost(mapString, mediaURL: mediaURL, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, completionHandler: { (success, error) in
                if let error = error {
                    self.displayErrorAlert("Error Posting", message: error, handler: nil)
                } else {
                    self.displayErrorAlert("Post Successful", message: "The post was saved!", handler: { (alertAction) in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
            })
        }
    }
    
    func cancelPost() {
        mapView.removeAnnotations(mapView.annotations)
        hideSaveCancelToolbar(true)
        if currentViewDisplayed === enterURLToShareView {
            swapViews(.LocationSelectionView)
        }
    }
    
    func swapViews(viewToShow: ViewToDisplay) {
        switch viewToShow {
        case .LocationSelectionView:
            UIView.animateWithDuration(0.5, animations: {
                self.enterURLToShareView.alpha = 0.0
                self.whatIsYourLocationView.alpha = 1.0
                self.currentViewDisplayed = self.whatIsYourLocationView
            }, completion: { [unowned self] (succes) in
                self.toolbarItems?[1] = self.saveLocationButton
            })
        case .URLtoShareView:
            UIView.animateWithDuration(0.5, animations: {
                self.whatIsYourLocationView.alpha = 0.0
                self.enterURLToShareView.alpha = 1.0
                self.urlTextField.becomeFirstResponder()
                self.currentViewDisplayed = self.enterURLToShareView
            }, completion: { [unowned self] (succes) in
                self.toolbarItems?[1] = self.savePostButton
            })
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
    
    
    func hideSaveCancelToolbar(show: Bool) {
        navigationController?.setToolbarHidden(show, animated: true)
    }
    
    func displayErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setupButons(textField: UITextField) {
        textField.delegate = self
        textField.autocorrectionType = .No
        textField.enablesReturnKeyAutomatically = true
        textField.clearButtonMode = .WhileEditing
        textField.textAlignment = .Center
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            displayBlurEffect(true)
            locationManager.requestLocation()
        }
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
                self.hideSaveCancelToolbar(false)
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 10 {
            if !urlTextField.text!.isEmpty {
                hideSaveCancelToolbar(false)
            } else {
                hideSaveCancelToolbar(true)
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        hideSaveCancelToolbar(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Make a Post"
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
        navigationItem.leftBarButtonItem = cancelButton
        
        savePostButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "savePost")
        saveLocationButton = UIBarButtonItem(title: "Use Location", style: .Plain, target: self, action: "saveLocation")
        trashButton = UIBarButtonItem(title: "Reset", style: .Plain, target: self, action: "cancelPost")
        flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbarItems = [flexSpace, saveLocationButton, flexSpace, trashButton, flexSpace]

        enterURLToShareView.alpha = 0.0
    }
}
