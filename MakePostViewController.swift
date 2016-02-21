//
//  MakePostViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/21/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import MapKit

class MakePostViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {

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
        
    }
    
    func getLocationFromEntry(locationString: String) {
        let geocoder = CLGeocoder()
        
        //BEGIN ACTIVITY INDICATOR/FADED BACKGROUND
        
        geocoder.geocodeAddressString(locationString) { (placemarkArray, error) in
            //END ACTIVITY INDICATOR/FADED BACKGROUND
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), {
                    self.displayErrorAlert("Error getting location", message: error.localizedDescription, handler: nil)
                })
            } else if let placemarks = placemarkArray {
                let placemark = placemarks[0]
                print(placemark)
            }
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
