//
//  PostAnnotation.swift
//  On the Map
//
//  Created by Michael Miller on 2/19/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import MapKit

//this custom class adopts the MKAnnotation protocol (by having the coordinate and two optional title and subtitle properties), which allows it to be used for generation map annotations; i used a custome class rather than the builtin MKPointAnnotation because i wanted to save the StudentInformation with each annotation, rather than simply the coordinate, title, and subtitle only
class PostAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var studentInfo: StudentInformation
    
    //the initializer is responsible for setting the annotation title to be the user name and the subtitle to be the URL, which are then displayed in the map view view controller; the initializer takes the StudentInformation of specific post as its argument and grabs the user's name, mediaURL, and latitude and longitude (as returned by parse), which are then used to generate a CLLocationCoordinate2D coordinate, as required by the MKAnnotation protocol
    init(studentInfo: StudentInformation) {
        self.studentInfo = studentInfo
        title = "\(studentInfo.firstName) \(studentInfo.lastName)"
        subtitle = studentInfo.mediaURL
        let latitude = CLLocationDegrees(Double(studentInfo.latitude))
        let longitude = CLLocationDegrees(Double(studentInfo.longitude))
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
