//
//  StudentInformation.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation

//this struct was designed to contain all the information that is retrieved from the parse server, for each specific post; the properties below match those from the data table that is returned by parse
struct StudentInformation {
    
    var objectID: String
    var uniqueKey: String
    var firstName: String
    var lastName: String
    var mapString: String
    var mediaURL: String
    var latitude: Float
    var longitude: Float
    var createdAt: String
    var updatedAt: String
    
    //this initializer takes a dictionary and uses its keys and values to initialize each struct instance
    init (dictionary: [String: AnyObject]) {
        self.objectID = dictionary["objectId"] as! String
        self.uniqueKey = dictionary["uniqueKey"] as! String
        self.firstName = dictionary["firstName"] as! String
        self.lastName = dictionary["lastName"] as! String
        self.mapString = dictionary["mapString"] as! String
        self.mediaURL = dictionary["mediaURL"] as! String
        self.latitude = dictionary["latitude"] as! Float
        self.longitude = dictionary["longitude"] as! Float
        self.createdAt = dictionary["createdAt"] as! String
        self.updatedAt = dictionary["updatedAt"] as! String
     }
}