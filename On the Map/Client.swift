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

class Client {
    
    struct Constants {
        static let udacitySessionURL = "https://www.udacity.com/api/session"
        static let udacityUserInfoURL = "https://www.udacity.com/api/users/"
        static let parseStudentLocationsURL = "https://api.parse.com/1/classes/StudentLocation"
        static let parseApplicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let RESTAPIKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    }
    
    static var udacityUserID: String?
    static var udacitySessionID: String?
    static var userFirstName: String?
    static var userLastName: String?
    static var facebookManager = FBSDKLoginManager()
    static var facebookToken: FBSDKAccessToken? {
        return FBSDKAccessToken.currentAccessToken()
    }
    
    class func createUdacitySession(username username: String, password: String, completionHandler: (success: Bool, error: String?) -> Void) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.udacitySessionURL)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json = ["udacity": ["username": username, "password": password]]
        
        request.HTTPBody = Client.getJSONForHTTPBody(json)
        //note: i decided to write a more generic method that creates a JSON HTTP body from a dictionary, rather than using a string that has the hard-coded structure; doing this was equivalent to: request.HTTPBody = "{\"udacity\": {\"username\": \"EMAIL", \"password\": \"PASSWORD\"}}".dataUsingEncoding(NSUTF8StringEncoding)

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if error != nil {
                
                //TODO: change localized descripte to parse out error string
                
                //completionHandler(success: false, error: error?.localizedDescription)
                completionHandler(success: false, error: "There was an error.")
                
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
                
                guard let udacityAccount = parsedData["account"] as? NSDictionary, udacitySession = parsedData["session"] as? NSDictionary else {
                    let error = parsedData["error"] as? String
                    completionHandler(success: false, error: error)
                    return
                }
                
                guard let key = udacityAccount["key"] as? String, sessionID = udacitySession["id"] as? String else {
                    completionHandler(success: false, error: "There was an error.")
                    return
                }
                Client.udacityUserID = key
                Client.udacitySessionID = sessionID

                self.getUdacityUserInfo(completionHandler)
            }
        }
        task.resume()
    }
    
    class func createUdacitySesssionFromFacebook(facebookAccessTokenString: String, completionHandler: (success: Bool, error: String?) -> Void) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.udacitySessionURL)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json = ["facebook_mobile": ["access_token": facebookAccessTokenString]]
        
        request.HTTPBody = getJSONForHTTPBody(json)
        //note: i decided to write a more generic method that creates a JSON HTTP body from a dictionary, rather than using a string that has the hard-coded structure; doing this was equivalent to: request.HTTPBody = "{\"udacity\": {\"username\": \"EMAIL", \"password\": \"PASSWORD\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if error != nil {
                
                //TODO: change localized descripte to parse out error string
                
                //completionHandler(success: false, error: error?.localizedDescription)
                completionHandler(success: false, error: "There was an error.")
                
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
                
                guard let udacityAccount = parsedData["account"] as? NSDictionary, udacitySession = parsedData["session"] as? NSDictionary else {
                    let error = parsedData["error"] as? String
                    completionHandler(success: false, error: error)
                    return
                }
                
                guard let key = udacityAccount["key"] as? String, sessionID = udacitySession["id"] as? String else {
                    completionHandler(success: false, error: "There was an error.")
                    return
                }
                Client.udacityUserID = key
                Client.udacitySessionID = sessionID
                
                self.getUdacityUserInfo(completionHandler)
            }
        }
        task.resume()
    }
    
    class func getUdacityUserInfo(completionHandler: (success: Bool, error: String?) ->  Void) {
    
        let url = Constants.udacityUserInfoURL + Client.udacityUserID!
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
    
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {data, response, error in
            
            if error != nil {
                
                //TODO: change localized descripte to parse out error string
                
                //completionHandler(success: false, error: error?.localizedDescription)
                completionHandler(success: false, error: "There was an error.")
                
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
                
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
    class func retreivePosts(completionHandler: (success: Bool, error: String?) ->  Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: Constants.parseStudentLocationsURL)!)
        request.addValue(Constants.parseApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.RESTAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                //TODO: change localized descripte to parse out error string
                
                //completionHandler(success: false, error: error?.localizedDescription)
                completionHandler(success: false, error: "There was an error.")
            } else {
                guard let data = data else {
                    completionHandler(success: false, error: "There was an error getting the data.")
                    return
                }
                
                guard let parsedData = parseData(data) else {
                    completionHandler(success: false, error: "There was an error converting the data.")
                    return
                }
                
                print(parsedData)
                guard let studentPosts = parsedData["results"] as? [NSDictionary] else {
                    completionHandler(success: false, error: "No posts found.")
                    return
                }
                
                print(studentPosts)
                
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
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
                completionHandler(success: false, error: "There was an error logging out.")
            } else {
                completionHandler(success: true, error: nil)
            }
        }
        task.resume()
    }
    
    class func logoutOfFacebook() {
        Client.facebookManager.logOut()
    }
    
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