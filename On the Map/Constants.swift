//
//  Constants.swift
//  On the Map
//
//  Created by Michael Miller on 3/9/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import CoreLocation

//MARK: CONSTANTS
struct Constants {
    
    //Client Constants
    static let udacitySessionURL = "https://www.udacity.com/api/session"
        //the backslashes as the end of the two strings below were added here for two of the URLs, as two of the methods that use them affix another piece on to the end and without the backslashes, the request would not process correctly; they alternatively could have been added elsewhere
    static let udacityUserInfoURL = "https://www.udacity.com/api/users/"
    static let parseStudentLocationsURL = "https://api.parse.com/1/classes/StudentLocation/"
    static let parseApplicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    static let RESTAPIKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    
    //LoginViewControllerConstants
    static let LoginSegueIdentifer = "LoginSuccessfulSegue"
    static let udacitySignUpURL = "https://www.udacity.com/account/auth#!/signup"
    static let loginErrorMissingInfoTitle = "Missing Info"
    static let loginErrorMissingInfoMessgae = "Username or password missing."
    static let loginWasCancelledTitle = "Login Not Successful"
    static let loginWasCancelledMessage = "Facebook login cancelled."
    static let generalLoginErrorTitle = "Login Error"
    
    //LocationsInTableViewController Constants
    static let openPostViewSegueFromTable = "SegueFromTableToPost"
    
    //LocationsInMapViewController Constants
    static let openPostViewSegueFromMap = "SegueFromMapToPost"
       //the two constants below define how far to zoom in around an annotation, and are used for zomming in automatically to the location of a newly added post by the user
    static let latitudeDelta: CLLocationDegrees = 0.2
    static let longitudeDelta: CLLocationDegrees = 0.2
    
    //MakePostViewControllerConstants
    static let latitudeDeltaMakePost: CLLocationDegrees = 0.05
    static let longitudeDeltaMakePost: CLLocationDegrees = 0.05
}