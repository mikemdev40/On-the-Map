//
//  PostAnnotation.swift
//  On the Map
//
//  Created by Michael Miller on 2/19/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import MapKit

class PostAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var studentInfo: StudentInformation
    
    init(studentInfo: StudentInformation) {
        self.studentInfo = studentInfo
        title = "\(studentInfo.firstName) \(studentInfo.lastName)"
        subtitle = studentInfo.mediaURL
        let latitude = CLLocationDegrees(Double(studentInfo.latitude))
        let longitude = CLLocationDegrees(Double(studentInfo.longitude))
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
