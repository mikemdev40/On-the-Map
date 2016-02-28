//
//  Client.swift
//  On the Map
//
//  Created by Michael Miller on 2/13/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit

//this class was created with all static variables and class methods, since there will and should only be only client instance at any given time
class Client {
    
    //MARK: CONSTANTS
    struct Constants {
        static let udacitySessionURL = "https://www.udacity.com/api/session"
        //the backslashes as the end of the two strings below were added here for two of the URLs, as two of the methods that use them affix another piece on to the end and without the backslashes, the request would not process correctly; they alternatively could have been added elsewhere
        static let udacityUserInfoURL = "https://www.udacity.com/api/users/"
        static let parseStudentLocationsURL = "https://api.parse.com/1/classes/StudentLocation/"
        static let parseApplicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let RESTAPIKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    }
    
    //MARK: PROPERTIES
    static var udacityUserID: String?
    static var udacitySessionID: String?
    static var userFirstName: String?
    static var userLastName: String?
    //the two properties below were creted for the purposes of tracking when an item was deleted or posted and were used by the two tab bar view controllers to determine whether to automatically refresh the data through a new download or not; further commentary on these two properties below when they are set
    static var didDeleteItem = false
    static var didPostItem = (false, false)
    
    //MARK: PROPERTIES FOR FACEBOOK LOGIN
    static var facebookManager = FBSDKLoginManager()  //instantiates a facebook manager, which enables the login process; the login method on this manager is invoked from the login view controller when the user taps the "login with facebook" button, the the resulting facebook token
    static var facebookToken: FBSDKAccessToken? {
        return FBSDKAccessToken.currentAccessToken()  //when established, this token is saved locally on the device automatically by the facebook SDK and allows the user to not have to login through facebook again
    }
    
    //MARK: CUSTOM CLASS METHODS
    ///class method that posts a session with udacity using the HTTP POST method, using login and password info supplied by user; this method then calls the "getUdacitySession" method (which was created to reduce redundancy in code) with the results
    class func createUdacitySession(username username: String, password: String, completionHandler: (success: Bool, error: String?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.udacitySessionURL)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json = ["udacity": ["username": username, "password": password]]
        //below, i decided to write a more generic "getJSONForHTTP" method that creates a JSON HTTP body from a dictionary, rather than using a string that has the hard-coded structure; doing this was equivalent to: request.HTTPBody = "{\"udacity\": {\"username\": \"EMAIL", \"password\": \"PASSWORD\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = Client.getJSONForHTTPBody(json)

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            getUdacitySession(data, response: response, error: error, completionHandler: completionHandler)
        }
        task.resume()
    }
    
    ///class method that posts a session with Udacity using a Facebook login; the facebookAccessTokenString is passed into this function when called from the login view controller, in which the "logInWithReadPermissions" method is invoked on the client's facebook manager instance and the resutling token is then stored on the device and passed into this method as an argument to be used in the udacity session creation
    class func createUdacitySesssionFromFacebook(facebookAccessTokenString: String, completionHandler: (success: Bool, error: String?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.udacitySessionURL)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json = ["facebook_mobile": ["access_token": facebookAccessTokenString]]
        request.HTTPBody = getJSONForHTTPBody(json)
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            getUdacitySession(data, response: response, error: error, completionHandler: completionHandler)
        }
        task.resume()
    }
    
    ///class method that was created to reduce identical code that is required for creating a udacity session from either a typical username/password login or from a facebook login; the method takes the data, response, error, and completion handler from either method (the completion handler is being passed from method to method, having originated from the login view controller code)
    class func getUdacitySession(data: NSData?, response: NSURLResponse?, error: NSError?, completionHandler: (success: Bool, error: String?) -> Void) {
        if error != nil {
            completionHandler(success: false, error: error?.localizedDescription)
            
        } else {
            //guard statements are used for the purpose of being able to use the unwrapped values defined in each guard statement to be accessible later
            guard let data = data else {
                completionHandler(success: false, error: "There was an error getting the data.")
                return
            }
            let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
            guard let parsedData = parseData(newData) else {
                completionHandler(success: false, error: "There was an error converting the data.")
                return
            }
            //there are certain errors that do not return the typical NSError, but rather returns an "error" with an associated message as a dictionary within the body of the "successfully" returned data (so the error checking at the start of the method doesn't catch the error, but this guard statement does)
            guard let udacityAccount = parsedData["account"] as? NSDictionary, udacitySession = parsedData["session"] as? NSDictionary else {
                let error = parsedData["error"] as? String
                completionHandler(success: false, error: error)
                return
            }
            guard let key = udacityAccount["key"] as? String, sessionID = udacitySession["id"] as? String else {
                completionHandler(success: false, error: "There was an error.")
                return
            }
            
            //sets the udacity user ID and session ID for the client; the user ID is used for retriving user info (which is needed to get the user's name) and for making posts (the "unigue key" field is the udacity user ID when a post gets saved); the sessionID is not actually utilized directly in the app, although setting it and making it available as part of the model's API makes for a more useful, potentially reusable model class (not that it is the intent to reuse this class exactly as is, but trying to stay in the mindset of reusability!)
            Client.udacityUserID = key
            Client.udacitySessionID = sessionID
            
            //the original completion handler just gets passed along, to ultimately be used at the end of the chained asynchoronous calls
            getUdacityUserInfo(completionHandler)
        }
    }
    
    ///class methods that retrieves the user's first name and last name, using a GET request to udacity with the user's ID, determined in the method above which calls this one
    class func getUdacityUserInfo(completionHandler: (success: Bool, error: String?) ->  Void) {
        let url = Constants.udacityUserInfoURL + Client.udacityUserID!
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
    
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {data, response, error in
            if error != nil {
                completionHandler(success: false, error: error?.localizedDescription)
                
            } else {
                guard let data = data else {
                    completionHandler(success: false, error: "There was an error getting the data.")
                    return
                }
                let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
                guard let parsedData = parseData(newData) else {
                    completionHandler(success: false, error: "There was an error converting the data.")
                    return
                }
                guard let udacityUser = parsedData["user"] as? NSDictionary else {
                    completionHandler(success: false, error: "No user data found.")
                    return
                }
                let firstName = udacityUser["first_name"] as? String
                let lastName = udacityUser["last_name"] as? String
                
                Client.userFirstName = firstName
                Client.userLastName = lastName
                
                //if this line is run, then that means the entire login process when smoothly without error (the completion handler passed in the original call to either createUdacitySession method from the login view controller gets invoked with a successful result and a nil error; if there was an error anywhere along the way, the completion handler would be invoked with an unsuccessful result and error message to be displayed in the login view controller's displayAlert)
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
    ///class method that retrieves all the post data from the parse server; the posts are returned through the completion handler as an array of dictionaries, which are then parsed appropriately by another class; the results were not parsed here, but rather passed out, for the purpose of increasing the generalizability and usability of this method, since the results can be broken down to get whatever data is needed, since a lot of data is returned back in the data array from parse
    class func retrieveStudentInformation(completionHandler: (success: Bool, error: String?, results: [NSDictionary]?) ->  Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.parseStudentLocationsURL)!)
        request.addValue(Constants.parseApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.RESTAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(success: false, error: error?.localizedDescription, results: nil)
            } else {
                guard let data = data else {
                    completionHandler(success: false, error: "There was an error getting the data.", results: nil)
                    return
                }
                guard let parsedData = parseData(data) else {
                    completionHandler(success: false, error: "There was an error converting the data.", results: nil)
                    return
                }
                guard let studentPosts = parsedData["results"] as? [NSDictionary] else {
                    completionHandler(success: false, error: "No posts found.", results: nil)
                    return
                }
                //if data retrieval is successful, the results are passed back to the original caller through the passed in completion handler
                completionHandler(success: true, error: nil, results: studentPosts)
            }
        }
        task.resume()
    }
    
    ///class method that creates a new post from user supplied info to the parse server through an HTTP POST method on the parse's web API (including the "map string" - what was actually typed into the location box, the URL to be shared in the post, as well as the latitude and longitude of the location, which are all required components for the post; the remaining required elements of the post are already stored as part of the client class)
    class func makePost(mapString: String, mediaURL: String, latitude: Double, longitude: Double, completionHandler: (success: Bool, error: String?) ->  Void) {
       
        //double checks to make sure that a user is succesfully logged into udacity and that the userID, firstName, and lastName properties are all set correctly
        guard let udacityUserID = udacityUserID, let userFirstName = userFirstName, let userLastName = userLastName else {
            completionHandler(success: false, error: "There was an issue with the logged in user's data.")
            return
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.parseStudentLocationsURL)!)
        request.addValue(Constants.parseApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.RESTAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var json = [String: AnyObject]()
        json = ["uniqueKey": udacityUserID, "firstName": userFirstName, "lastName": userLastName, "mapString": mapString, "mediaURL": mediaURL, "latitude": latitude, "longitude": longitude]
        //as mentioned above, a more generic method that creates a JSON HTTP body from a dictionary was developed and used below, rather than using the hard-coded string structure; doing this was equivalent to: request.HTTPBody = "{\"uniqueKey\": \"1234\", \"firstName\": \"John\", \"lastName\": \"Doe\",\"mapString\": \"Mountain View, CA\", \"mediaURL\": \"https://udacity.com\",\"latitude\": 37.386052, \"longitude\": -122.083851}".dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = getJSONForHTTPBody(json)

        let session = NSURLSession.sharedSession()
        
        //the returned data from the data task was not needed or used since this was a simple POST, and all that was needed was to make sure no error occurred
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(success: false, error: error?.localizedDescription)
            } else {
                //the didPostItem variable allows for the two tab view controllers to know that a refresh is needed, since a post was made; once a post is made, each tab view controller looks at this value when it appears for the first time since the post was made, and if its corresponding tuple value (the first, or .0, for the map view controller and .1 for the table view controller) is true, that tab refreshes the data for its view (either map or table), then sets the corresponding tuple property to false to show that, next time the view appears, that a refresh isn't needed unless another was post was made by the user in the meantime; it should be noted that i didn't really like putting this property in this class, as it felt like it makes the class - which has otherwise been designed to be as standalone as possible and as "view controller independent" - feel a bit too "customized" for the two view controllers in this app (since the choice for a tuple with TWO values was a result of there being two tab bar view controllers!); i could have (and probably should have) placed this "tracking" property in the app delegate or another shared structure, but ended up just putting it in this class for simplicity
                didPostItem = (true, true)
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
    ///class method that deletes a post from the parse server using the HTTP DELETE method; although this method was not required for this project (or even advertised in the project documentation), i thought it would be a fun addition and so did a little perusal of the parse documentation on my own to figure it out; in the app, this method is invoked when a user puts the table view into edit mode (view the EDIT button), then deletes one of his or her posts (only!) from the table view (the objectID, which is the unique value generated automatically by parse and saved as part of the student information that is retrieved, is pulling from the student post data associated with the specific table row cell and passed into this method); even though this method should theoretically work on ANY post by ANY udacity user (simply by grabbing the objectID for someone else's post), the table view ONLY allows deleting for posts that have a userID that matches the logged in userID (posts that are NOT associated with the logged in user's ID do NOT have a delete button appear in the table); i say "theoretically" since i did not actually test the deletion of anyone else's post (of course!)
    class func deletePost(objectId: String, completionHandler: (success: Bool, error: String?) ->  Void) {
        
        //the url to delete is the same as used for posting, with the addition of the objectID of the item to delete
        let url = Constants.parseStudentLocationsURL + objectId
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.addValue(Constants.parseApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.RESTAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.HTTPMethod = "DELETE"
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(success: false, error: error?.localizedDescription)
            } else {
                
                //similar to methods above, some possible "errors" that occur which are not technically "errors" in the NSError sense, are passed back as part of the data body; one such error i came across (acidentally) was an invalid objectID, which results in an error message within the data body, but the "error" value that is passed as part of the tasks's completion is still nil! however, when this occurred, the STATUS CODE on the response was 400, so i used a check on the status code to make sure it fell within the 200-299 range of success (as was done in the movie manager app; if the objectID was found and deleted successfully, the response's status code was 200); so the way this was resolved was that i first pulled out the error string and saved it to be passed with the completion handler, then used a guard statement to check that the status code was in acceptable range
                var errorMessage: String? = nil
                if let data = data {
                    if let parsedData = parseData(data) {
                        errorMessage = parsedData["error"] as? String
                    }
                }
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    if let errorString = errorMessage {
                        completionHandler(success: false, error: errorString)
                    } else {
                        completionHandler(success: false, error: "There was an error deleting the object.")
                    }
                    return
                }
                
                //similar to the didPostItem property, this was included with this class for the purpose of the map view controller to be able to check to see if a post was deleted, and if so, to refresh its view when it first appears after a post is deleted by the user; a tuple is not needed here, since only the map view controller needs to check, as the table view controller is the only place that a deletion can be made, and as soon as a deletion IS made, the table automatically updates, so it is not necessary to have a "tracking" variable for the table view controller (same commentary on my feelings about this as described above)
                didDeleteItem = true
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
    ///class method that logs the user out of the udacity session by sending a DELETE message, along with other information regarding cookies (although i strongly dislike adding code to a project that i don't fully understand, i made an expcetion here and used the cookie-related code provided in the udacity documentation, although i readily admit that i do not fully understand the workings of cookie storage, etc.; i am making a note of it that i need to spend some time figuring this out!)
    class func logoutOfUdacity(completionHandler: (success: Bool, error: String?) ->  Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.udacitySessionURL)!)
        request.HTTPMethod = "DELETE"
        var xsrfCookie: NSHTTPCookie? = nil
        let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(success: false, error: error?.localizedDescription)
            } else {
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
    ///class method that invokes the logOut method of the facebook manager to log the user out of a facebook session (if it was active); without knowing exactly what is going on behind the scenes of the facebook SDK, the logOut method is definitely involved in nullifying the current active facebook token, thus setting FBSDKAccessToken.currentAccessToken() to nil, which, when checked when the user tries to login with facebook, leads to an additional login step which gets a new token
    class func logoutOfFacebook() {
        Client.facebookManager.logOut()
    }
    
    ///class helper method that takes JSON NSData and returns an optional NSDictionary (nil if there was an error converting it from JSON to a dictionary); the method utilizes NSJSONSerialization and related methods; this method is used many times throughout this class to convert JSON data to a readable format
    class func parseData(dataToParse: NSData) -> NSDictionary? {
        let JSONData: AnyObject?
        do {
            JSONData = try NSJSONSerialization.JSONObjectWithData(dataToParse, options: .AllowFragments)
        } catch {
            return nil
        }
        guard let parsedData = JSONData as? NSDictionary else {
            return nil
        }
        return parsedData
    }
    
    ///class helper method that takes a dictionary and converts it to JSON data for the purpose of transmitting it as part of the HTTPbody of the NSMutableURLRequest, as utilized in the two createUdacitySession methods and the makePost method
    class func getJSONForHTTPBody(dictionary: [String: AnyObject]) -> NSData? {
        let JSONForHTTPBody: NSData?
        do {
            JSONForHTTPBody = try NSJSONSerialization.dataWithJSONObject(dictionary, options: .PrettyPrinted)
        } catch {
            JSONForHTTPBody = nil
        }
        return JSONForHTTPBody
    }
}