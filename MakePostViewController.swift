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

//the many IBOutlets and IBActions of this class result from the design of this view controller in the interface builder; getting the setup of these views correct (particularly with regards to the stackviews, animations, and keyboard responses) was tricky (and frustrating!) but worth it in the end (at least i think!)
class MakePostViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate {
    
    //this enumeration is used for convenience when swapping the location view and the URL entry view (as discussed in more detail in the swapViews method below
    enum ViewToDisplay {
        case LocationSelectionView, URLtoShareView
    }
    
    //MARK: OUTLETS
    //to reduce code redundancy, both text fields call the setupButtons method, passing themselves as the argument, to have all their settings set up; note that these settings could also have been set in interface builder, but i chose to to them in code
    @IBOutlet weak var locationTextField: UITextField! {
        didSet {
            setupButons(locationTextField)
        }
    }
    
    @IBOutlet weak var urlTextField: UITextField! {
        didSet {
            setupButons(urlTextField)
        
            //the tag value of this text field is used to distinguish between the URL text field and the location text field when calling the textFieldDidEndEditing delegate method; the value of 10 is entirely arbitrary
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
    
    //the two outlets below represent the yellow URL sharing view (which is shown on top in the storyboard, simply because it was designed second) and the orange location sharing view; both views needed outlet references, as they are animated in and out
    @IBOutlet weak var enterURLToShareView: UIView!
    @IBOutlet weak var whatIsYourLocationView: UIView!
    
    //this spinner shows when the geocoder is searching for a location, on top of the blurView
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    //MARK: PROPERTIES
    //this property is used to enable the blurry effect that appears under the spinner when the geocoder is searching for a location
    let blurView = UIVisualEffectView()
    
    var saveLocationButton: UIBarButtonItem!
    var savePostButton: UIBarButtonItem!
    var trashButton: UIBarButtonItem!
    var flexSpace: UIBarButtonItem!
    
    //this property is used to track the current view, for use when the orange and yellow views are swapped
    var currentViewDisplayed: UIView?

    //this property sets up a location manager for the purpose of using the reverse geolocation services to find the user's current location, in the event they tap the "use current location" button; the use of a lazily initialized variable was chosen because a location manager is only needed (and invoked) in the case that the user taps the "use current location" button; otherwise, it isn't ever used (so the lay initialization allows for it to be initialized when needed); although it would have been easier (and equally as viable) to have "let lazyLocationManager = CLLocationManager()" as a property, and set its delegate and desiredAccuracy properties in viewDidLoad or in a didSet property observer, i felt it made for better practice to utilize lazy in this case, since not all users of the app will utilize the "use current location" feature (and so the location manager would not be needed), and use of location services - at least in my experience - can be a battery drain!
    lazy var locationManager: CLLocationManager = {
        let lazyLocationManager = CLLocationManager()
        lazyLocationManager.delegate = self
        lazyLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        return lazyLocationManager
    }()
    
    //MARK: CUSTOM METHODS
    ///method connected to the "SUBMIT" button underneath the location text field, which first checks to make sure the location text field isn't empty; if so, an alert is displayed, and if not (and the user has presumably entered a location), the location text is sent to the getLocationFromEntry method and the text field resigns its first responder status
    @IBAction func findOnTheMap(sender: UIButton) {
        if locationTextField.text!.isEmpty {
            displayErrorAlert("Empty location", message: "Please enter a location.", handler: nil)
            locationTextField.resignFirstResponder()
        } else {
            getLocationFromEntry(locationTextField.text!)
            locationTextField.resignFirstResponder()
        }
    }
    
    ///method connected to the "Use Current Location" button, and it is only at this time that the user is asked for permission for the app to use location services (the "when in use" option was elected for this app, and entered as required in the info.plist); once tapped, the location manager gets (lazily) initialized and checks the app's authorization status, responding approriately based on whether the user has already granted permission (or not); assuming
    @IBAction func useCurrentLocation(sender: UIButton) {
        
        switch CLLocationManager.authorizationStatus() {
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        //if location services have already been enabled, then the blur visual effect view is added to the view hierarchy and the spinner is started (both via the displayBlurEffect method), and the specilized "requestLocation()" method on the locationManager is invoked, which returns a single location of the user, calls the didUpdateLocations location manager delegate method with that single location, then disables location updates (this is opposed to using the locationManager.startUpdatingLocation method, which will continuously track a user's location, an unnecessary action for this app's purposes)
        case .AuthorizedWhenInUse:
            displayBlurEffect(true)
            locationManager.requestLocation()
            
        //the case below is never actually accessed because this level of authorization is not requested; it is simply added here for switch completeness
        case .AuthorizedAlways:
            displayBlurEffect(true)
            locationManager.requestLocation()
        
        //in the event none of the above are true, that means the user has responded "don't allow" to the prompt at an earlier time
        default:
            displayErrorAlert("Location services disabled", message: "Please re-enable location services in Settings for this app to use this feature!", handler: nil)
        }
    }
    
    ///method that is invoked when the user taps the "SUBMIT" button after typing in a location to search for, with the location string being passed as the argument; this method finds the location using the geocodeAddressString method on an object of the CLGeocoder class
    func getLocationFromEntry(locationString: String) {
        let geocoder = CLGeocoder()
        
        //adds the blur visual effects view and starts the spinner
        displayBlurEffect(true)

        //when the call to geocodeAddressString is returned, error checking occurs, and then the first placemark is pulled out of the returned placemark array (there should atually only be one element in the array to begin with), which is sent along with the typed in string as arguments to the placePinOnMap method (which places the pin on the map); once the location pin is added to the map, the call to hideSaveCancelToolbar allows the toolbar - which is hidden at first to appear, and displays the user with two options: "Use Location" (which saves the location and brings up the URL view) or "Reset" (which cancels the post, resets the text field, and removes the pin from the map)
        geocoder.geocodeAddressString(locationString) {[unowned self] (placemarkArray, error) in
            
            //note that it wasn't necessary to dispatch to main queue inside this completion handler closure, even though updates are being made to the UI, since the completion handler for the geocoder completes on the main thread, as per the documentation
            self.displayBlurEffect(false)
            if let error = error {
                self.displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
            } else if let placemarks = placemarkArray {
                let placemark = placemarks[0]
                
                //the placemark gets sent to this method to get parsed and placed on the map as a pin
                self.placePinOnMap(placemark, originalString: locationString)
                
                //unhides the toolbar, which then presents the user with two options: "Use Location" or "Reset"
                self.hideSaveCancelToolbar(false)
            }
        }
    }
    
    ///method that is responsible for placing the geocoded location on the map, taking in he placemark and originally typed location text as parameters; this method gets called from both methods the use geocoding: the getLocationFromEntry method (in which the user types a location and geocoder uses forward geocoding to get a placemark) or the useCurrentLocation method (in which user opts to use his/her current location, which uses reverse geocoding to get a placement); if the user searched for a specific location, the initially entered text is used as the pin's title (and also what gets saved as the location in the saved post), whereas certain information is parsed out of the placemark to generate the subtitle (such as city, state, and country); if the user is using the current location (i.e. did not enter a string), then instead of using the original string as the title (and as the location in the post), the method searches through the placemark and uses certain elements to comprise the location string; the placemark is added as an anotation via the built-in MKPointAnnotation class, and lastly added to the map view (an MKPinAnnotationView is used, with a green color) and zoomed in on; the reason a location string is needed is because, in the table view, the location is one of the pieces of information that is shown for the post
    func placePinOnMap(placemark: CLPlacemark, originalString: String?) {
        
        //pulls out the CLLocation information from the CLPlacemark
        if let location = placemark.location {
            
            let annotation = MKPointAnnotation()
            
            //a variable that is used to generate the string to be used as the subtitle for the annotation (which is for the pin only and will not be saved in the user's post)
            var placemarkComponents = [String]()
            
            //sets the required CLLocationCoordinate2D property of the annotation using the placemark's location's coordinate property
            annotation.coordinate = location.coordinate
            
            //creates the subtitle string using the components of the placemark (some of which may be nil depending on the location entered), and then joins them with ","
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
            //if all four components are not nil, the string would be visibly too long for the annotation, so the last one (country) is removed
            if placemarkComponents.count == 4 {
                placemarkComponents.removeLast()
            }
            let placemarkInfo = placemarkComponents.joinWithSeparator(", ")
            annotation.subtitle = placemarkInfo
            
            //if this method was called from the getLocationFromEntry method, the user has entered a location and so the originalString is non-nil (and so the annotation's title is simply set to this original string, and this string will ultimately be saved in the user's post as the "mapString" property); however, if this method called from the useCurrentLocation method, there will be no information to include as the location string, so it is necessary to generate one to ultimately be saved as the "map string" with the user's post (since creating a StudentInformation instance requires a "mapString" value, not to mention that the table view cells show location information!)
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
            
            //clears out any present pins on the map, in the event there is already one on the map, such as if the user tapped "reset" and then re-entered a new location
            mapView.removeAnnotations(mapView.annotations)
            
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: Constants.latitudeDeltaMakePost, longitudeDelta: Constants.longitudeDeltaMakePost))
            mapView.setRegion(region, animated: true)
            
            //adds the annotation to the map, which will lead to the viewForAnnotation delegate method being called, which will return a green pin to be displayed
            mapView.addAnnotation(annotation)
            
            //automatically selects the annotation, thus bringing up the callout for display (since there is only one annotation in the map view, calling the first, or [0], element will always return the annotation that was just added)
            mapView.selectAnnotation(mapView.annotations[0], animated: true)
        }
    }
    
    ///method that is attached to the "Use Location" button in the navigation controller's toolbar (which is hidden at first, but then appears when the geocoding completes, either as part of the getLocationFromEntry or the useCurrentLocation methods); this method swaps the views using the swapViews method with the .URLtoShareView enum value, which corresponds to "swap out the location view and show the URL view"; once the swapping has occurred and the URL entry view is showing (the yellow one), the toolbar gets hidden again
    func saveLocation() {
        swapViews(.URLtoShareView)
        hideSaveCancelToolbar(true)
    }
    
    ///method that is attached to the "Save" system button in the navigation controller's toolbar, which is presented again to the user once a URL is entered in the URL entry view's text field (note that the swapViews method also changes the bottom left button from "Save Location" to "Save," the button that this method is attached to, when the URL view is presented); this method is responsible for saving the post by first ensuring that a URL has been entered (the URL text field is not empty) and that there is an annotation on the map (which should always be the case); once that is done, the title and location information are extracted from the annotation, and then the Client.makePost is called (sending the title as the mapString, the text field's text as the mediaURL, and the latitude and longitude from the annotation's coordinate propert as the arguments), which actually commits the post to the parse server and returns results in a completion handler; if an error occurred while posting, an alert is displayed, otherwise, an alert shows that the post was successful and the MakePostViewController is dismissed
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
                dispatch_async(dispatch_get_main_queue(), {
                    if let error = error {
                        self.displayErrorAlert("Error Posting", message: error, handler: nil)
                    } else {
                        self.displayErrorAlert("Post Successful", message: "The post was saved!", handler: { (alertAction) in
                            self.dismissViewControllerAnimated(true, completion: nil)
                        })
                    }
                })
            })
        }
    }
    
    ///method that performs the swap of the location entry view (the orange one, the "whatIsYourLocationView" outlet) and the URL entry view (the yellow one, the "enterURLToShareView" outlet), and also updates the navigation controller toolbar's left button (it originally starts out as the "Save Location" button, then when the user taps that and brings up the URL entry view, the button is updated to "Save" for when the user enters the URL to share); this method also gets called when the user taps "Reset" after either entering a location or a URL; the "swapping" that occurs is an animation which takes the alpha of the "swapping out" view to 0 and takes the alpha of the "swapping in" view to 1.0, which yields a dissolve out/in effect; the currentViewDisplayed property is also updated to whichever view just swapped in, for use in the cancelPost method (if needed), and if the URL view is the view swapping in, the URL text field is made the first responder, which automatically brings up the keyboard
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
    
    ///method that is attached to the "Reset" button that appears in the navigation controller's toolbar when it is visible, and performs cleanup of the map by removing any annotation that was just added to the map, re-hides the toolbar, and if the currently showing view is the URL entry view (the yellow one) when the "Reset" button is tapped, the swapViews method is called which swaps back to the location entry view (the orange one)
    func cancelPost() {
        mapView.removeAnnotations(mapView.annotations)
        hideSaveCancelToolbar(true)
        
        //since reference types are being compared here, it was necessary to use the "identical to" identity operator (===) to check to see if the saved currentViewDisplayed variable refers to the same UIView instance as the URL entry view (i.e. the URL entry view is showing); the currentViewDisplayed variable gets updated within the swapViews method
        if currentViewDisplayed === enterURLToShareView {
            swapViews(.LocationSelectionView)
        }
    }
    
    ///method that adds (or removes) the blur effect over the map view along with turning the spinner on, for use when the geocoding is occurring; the blur effect is created by adding the blurView (which is a UIVisualEffectView) as a subview of the mapView and adding an animated blur effect; passing "true" as the arguement enables the blurview and spinner, and passing "false" disables it (which simply removes the view from the mapview and stops the spinner, which hides itself when stopped)
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
    
    ///method that toggles the navigation controller's toolbar between visible and hidden; a "true" argument results in the toolbar being hidden and a "false" argument results in the toolbar being made visible; the purpose of hiding and unhiding the toolbar is to only have the toolbar presented when the user can continue, i.e. by having entered the necessary info (it appears after the user enters a location or presses the "use current location" button and the geocoding is sucessful, presenting the "Use Location" button; disappears while the user is entering a URL; then reappears when something has been entered in the URL entry text field, thus signaling to the user that the post can now be saved, at which point the "Save" button has taken the place of the "Use Location")
    func hideSaveCancelToolbar(show: Bool) {
        navigationController?.setToolbarHidden(show, animated: true)
    }
    
    ///method that displays an alert to the user with single "OK" button (used to indicate both errors and successes), and takes a title string, message string, and optional completion handler; as a note, i reused this method directly from another project and left the optional completion handler as part of the structure, even though none of the calls to this method within this app utilize a completion handler (i.e. all calls pass in nil for the third argument)
    func displayErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    ///method that is connected to the "Cancel" button in the top left corner of the MakePostViewController and simply dismisses itself, having been modally presented by another view controller
    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    ///method that performs setup of both the locationTextField and urlTextField
    func setupButons(textField: UITextField) {
        textField.delegate = self
        textField.autocorrectionType = .No
        textField.enablesReturnKeyAutomatically = true
        textField.clearButtonMode = .WhileEditing
        textField.textAlignment = .Center
    }
    
    //MARK: DELEGATE/DATASOURCE METHODS
    //this delegate method gets called only after the very first time the user authenticates the app to use location services; it is included here to ensure that the location request gets made immediately after the user approves location services (without this method, the locationManager.requestLocation() method would not get called immediately after the user approves location services, because the useCurrentLocation method only gets called once when the "use current location" button is tapped and the .NotDetermined case in the switch statement only invovles asking the user's permission but not actually making the requestLocation call)
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            displayBlurEffect(true)
            locationManager.requestLocation()
        }
    }
    
    //this delegate method gets called in response to locationManager.requestLocation() and returns a single location data point in the locations array; this location is then reverse geocoded using an object of the CLGeocoder class, and the placemark that gets returned is then turned into an annotation and pin on the map via the placePinOnMap method
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //note that there will only be one element in the array in this case, since the locationManager.requestLocation() returns only one location before location services are stopped; this array would have more in it if startUpdatingLocation() had been called instead
        let userLocation = locations[0]
        
        let geocoder = CLGeocoder()
        
        //when the call to reverseGeocodeLocation is returned, error checking occurs, and then the first placemark is pulled out of the returned placemark array (there should atually only be one element in the array to begin with, which is sent along with the typed in string as arguments to the placePinOnMap method (which places the pin on the map); once the location pin is added to the map, the call to hideSaveCancelToolbar allows the toolbar - which is hidden at first - to appear, and displays the user with two options: "Use Location" (which saves the location and brings up the URL view) or "Reset" (which cancels the post, resets the text field, and removes the pin from the map)
        geocoder.reverseGeocodeLocation(userLocation) { (placemarkArray, error) in
            
            //note that it wasn't necessary to dispatch to main queue inside this completion handler closure, even though updates are being made to the UI, since the completion handler for the geocoder completes on the main thread, as per the documentation
            self.displayBlurEffect(false)
            if let error = error {
                self.displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
            } else if let placemarks = placemarkArray {
                let placemark = placemarks[0]
                
                //the placemark gets sent to this method to get parsed and placed on the map as a pin
                self.placePinOnMap(placemark, originalString: nil)
                
                //unhides the toolbar, which then presents the user with two options: "Use Location" or "Reset"
                self.hideSaveCancelToolbar(false)
            }
        }
    }
    
    //this delegate method is called in the event the call to locationManager.requestLocation() times out, failing to retrieve a location fix on the user, and displays an alert with the error message; as mentioned in the documentation, when using the requestLocation method, it is required that both didUpdateLocations and the didFailWithError delegate methods are implemented
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
    }
    
    //this delegate method returns the MKAnnoationView to use for the location annotation that gets placed on the map; the cast to MKPinAnnotationView is done so that the pin's color can be changed to green (from the default red)
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
    
    //MARK: DELEGATE/DATASOURCE METHODS
    //this delegate method causes the keyboard to dismiss when the user taps "return" on the text field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    //this delegate method is of particular importance when the user is entering a URL in the URL entry text field; when the user either hits "return" (or taps someone else), thus resigning first responder status, this delegate method checks to see if the URL text field is empty and if it is, hides the toolbar (so that the "save" button is not accessible), and if it isn't (i.e. the user has entered the URL), presents the toolbar with the "Save" button showing; the tag property is used here so that the toolbar hiding behavior only occurs for the URL text field (which has its tag set to the arbitrary value of 10)
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 10 {
            if !urlTextField.text!.isEmpty {
                hideSaveCancelToolbar(false)
            } else {
                hideSaveCancelToolbar(true)
            }
        }
    }
    
    //MARK: VIEW CONTROLLER METHODS
    //this method is used in this app for the purpose of dismissing the keyboard when the user taps anyone on the screen that is not in the textfield
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    //when the view appears, the location text field is assigned first responder so that the keyboard is automatically presented
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        locationTextField.becomeFirstResponder()
    }
    
    //when the view is about to appear, the navigation controller's toolbar is hidden (and will be presented again once a location is entered and "submit" tapped, or the user taps the "use current location" button)
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        hideSaveCancelToolbar(true)
    }
    
    //when the view loads, a "Cancel" button is added to the navigation bar and all the buttons that will be used in the navigation controller's toolbar are created, with the initial ordering set; the saveLocationButton and savePostButton will be exchanged depending on where the use is in the process of creating a location/URL post; lastly, the URL view's alpha is initially set to 0 (effectively hiding it from view), which will change as part of the swapView method's animation
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Make a Post"
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
        navigationItem.leftBarButtonItem = cancelButton
        
        saveLocationButton = UIBarButtonItem(title: "Use Location", style: .Plain, target: self, action: "saveLocation")
        savePostButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "savePost")
        trashButton = UIBarButtonItem(title: "Reset", style: .Plain, target: self, action: "cancelPost")
        flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbarItems = [flexSpace, saveLocationButton, flexSpace, trashButton, flexSpace]

        enterURLToShareView.alpha = 0.0
    }
}
