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

    //MARK: CONSTANTS
    struct Constants {
        static let openPostViewSegue = "SegueFromMapToPost"
        
        //these two constants define how far to zoom in around an annotation, and are used for zomming in automatically to the location of a newly added post by the user
        static let latitudeDelta: CLLocationDegrees = 0.2
        static let longitudeDelta: CLLocationDegrees = 0.2
    }
    
    //MARK: OUTLETS
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.mapType = .Standard
            mapView.userTrackingMode = .None
        }
    }
    
    //MARK: CUSTOM METHODS
    ///method that is associated with the post button in the navigation bar; the tab bar class itself is responsible for setting the target of the post button to be this view controller, at which point, this post method is the action that runs when the post button is pressed
    func post() {
        performSegueWithIdentifier(Constants.openPostViewSegue, sender: self)
    }
    
    ///method that is associated with the refresh button in the navigation bar (and as with the post button, the tab bar class itself is responsible for setting the target of the refresh button to be this view controller, at which point, this refresh method is the action that runs when the refresh button is pressed); when this method is invoked, the network indicator starts spinning to show network activity, all posts are cleared out to be re-downloaded (if this method is running for the very first time, there is nothing to clear out), and a call is made to the Client.retrieveStudentInformation method, which is responsible for downloading all the post data from parse; if there are results (and no error) to display, then a call is made to the StudentPosts.generatePostsFromData, which builds the array from all the post data that the map uses as the datasource for its annotations, and then calls the createAndAddAnnotations method, which actually creates an annotations array that will ultimately get added to the mapview to show as pins; after these actions take place, the first element of the Client.didPostItem tuple (the element designated for the map view controller) is set back to false (it occurs here and not within the viewWillAppear, as is the case for the table view controller, because the createAndAddAnnotations also checks the value of Client.didPostItem.0 to see if its true, and if so, the map automatically zooms into the new annotation; if there is no new user post, i.e. Client.didPostItem.0 already is false, then no zoom occurs
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
    
    ///method that creates an array of PostAnnotations (a custom class that conforms to the MKAnnotation protocol) using the StudentInformation data stored in the StudentPosts.sharedInstance.posts shared data model; the PostAnnotations are created using the initializer that accepts a StudentInformation object, from which the information related to the annotation (title, subtitle, and coordinate) is extracted and the required properties constructed; the array of PostAnnotations are then added to the map in a single batch, and if this method is getting called after a new post was made by the user (Client.didPostItem.0 = true), then after adding the annotations to the map, the map will zoom in automatically around the location of the pin corresponding to the user's new post
    func createAndAddAnnotations() {
        if !StudentPosts.sharedInstance.posts.isEmpty {
            
            //clears out all annotations first, if there are any, before adding them
            mapView.removeAnnotations(mapView.annotations)
            
            //array that will have annotations added to it, to ultimately be added to the mapview
            var annotationsToAdd = [PostAnnotation]()
            
            //the two variables below are used to track whether a post made by the user is found when iterating through all posts during annotation set, and if so, it captures the first one it comes to (which is the most recent one by the user, since the data returned by parse is, be default, in order from newest to oldest), and then sets the boolean to true so it doesn't capture another one
            var didFindLatestUserPost = false
            var annotationToZoomTo: PostAnnotation?
            
            for studentInfo in StudentPosts.sharedInstance.posts {
                let annotation = PostAnnotation(studentInfo: studentInfo)
                annotationsToAdd.append(annotation)
                
                //for each post, if the logged in userID equals the userID associated with the post AND it's the first post during the iteration to be the user's (didFindLatestUserPost == false), then this annotation is captured for the purpose of possibly being zoomed into; this was necessary because simply grabbing annotationsToAdd[0] was not logically sound since it is not guaranteed that the very most recent post is the user's (it is possible that someone else made a post AFTER the user did, but before the user switched back to the map view); i had incorrectly included such logic, but caught the error in logic while typing up the documentation
                if annotation.studentInfo.uniqueKey == Client.udacityUserID && didFindLatestUserPost == false {
                    annotationToZoomTo = annotation
                    didFindLatestUserPost = true
                }
            }
            
            mapView.addAnnotations(annotationsToAdd)
            
            //this part of the method only runs if there is a NEW post by the user (Client.didPostItem.0), and the most recent user post was found and captured above in annotationToZoomTo (which it should have, since a post was just made!); if these are both true, the map zooms into that post
            if Client.didPostItem.0, let annotationToZoomTo = annotationToZoomTo {
                let region = MKCoordinateRegion(center: annotationToZoomTo.coordinate, span: MKCoordinateSpan(latitudeDelta: Constants.latitudeDelta, longitudeDelta: Constants.longitudeDelta))
                mapView.setRegion(region, animated: true)
                mapView.selectAnnotation(annotationToZoomTo, animated: true)
            }
        }
    }
    
    ///method that displays an alert to the user with single "OK" button (used to indicate both errors and successes), and takes a title string, message string, and optional completion handler; as a note, i reused this method directly from another project and left the optional completion handler as part of the structure, even though none of the calls to this method within this app utilize a completion handler (i.e. all calls pass in nil for the third argument)
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    //MARK: DELEGATE/DATASOURCE METHODS
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        //the short if statement below prevents the user's location from being presented as a red pin, and enables the annotation for the user location to retain its default blue dot beacon; the map view originally showed the user's location, but i decided to remove this feature as it didn't really add anything to user experience and by enabling the user location for this view, the user is prompted to allow the app to use the location of the user immediately upon logging in, which was not the best place to ask for user permission to allow location services (as it wasn't immediately evident why location services would be needed without having even seen the app); as a result, i removed the user tracking on this map; the one place where location services are used is in the MakePost view, when the user taps the "use current location," at which point the user is asked for permission - which is a much more logical place to ask for permission!  with that all said, i did decide, however, to keep this short piece of "checking" code below, even though it isn't needed here, for the purpose of maintaining the scalability of the code in this method just in case i want to use it again in the future (such as if i ever decide to update the interface to include the user location, or just want to copy/paste it for use in another app)
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        //it was necessary to case the annotationView as an MKPinAnnotationView so that the pinTintColor could be directly accessed below (even though i ended up just sticking with red, which is the default); without the downcast, the annotationView would be an MKAnnotationView, which does not have a pinTintColor property that can be set directly (and uses the red pin by default)
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
    
    //this delegate method gets invoked when the callout's accessory button gets tapped, or the whitespace of the callout (i.e. to the left of the "i" callout accessory button); interestingly, tapping the added "whitespace" only invokes this delegate method in the case of the accessory button being the "detail disclosure" button; for other button types, this methods gets invoked ONLY when the actual acesory button is tapped, but not the whitespace (i am not sure why this exception exists); once the accessory button (or callout whitespace) is tapped, a safari view controller is initialized using the URL associated with the callout (its subtitle) by using the URL-based initilizer of the SFSafariViewController class; because there are currently issues with opening up URLs using the SFSafariViewController class that do not start with a proper scheme (e.g. http or https, as discussed here http://stackoverflow.com/questions/32864287/sfsafariviewcontroller-crashing-on-valid-nsurl ), the method checks to first see if the scheme contains either of those prefixes, and if so, it launches the safari view controller, and if NOT, then an "http://" prefix is attached (i got this idea from the stackoverflow post); once the user is done navigating the safari window, clicking the "Done" button in the top left will bring them back to the map view; the SFSafariViewController class is being used instead of invoking UIApplication.sharedApplication().openURL(newNSURL), as the SFSafari class has the added benefit of not requiring the user to leave the app (as discussed here: http://code.tutsplus.com/tutorials/ios-9-getting-started-with-sfsafariviewcontroller--cms-24260 )
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
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
                        }
                    }
                }
            }
        }
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    //when the view is about to appear, either from the MakePostViewController being dismissed (if the map was the tab the user was on when the post button was tapped) or from switching from the table view, there is a quick check to the Client.didDeleteItem to see if a post(s) has been deleted by the user, and if so, to get refresehd info, and there is also a check to the first element of the Client.didPostItem tuple (the element designated for the map view controller) to see if a new post has been made since the table view was last seen; if so, the map is refreshed so as to capture on the map any new post by the user (and any others that may have been made by other udacity users during that time); the value of Client.didPostItem.0 is not set to false immediately (as done for Client.didDeleteItem), since another check is made to this value as part of the refresh process to determine if the map should automatically zoom in to the most recent user post or not (at which point it is then set to false)
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
    
    //when the view loads for the first time, a refresh occurs to place initial pins on the map
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    }
}
