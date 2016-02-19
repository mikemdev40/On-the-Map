//
//  StudentPosts.swift
//  On the Map
//
//  Created by Michael Miller on 2/19/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation

class StudentPosts {
    static let sharedInstance = StudentPosts()
    var posts = [StudentInformation]()
    
    private init() { }
}