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
    
    static func clearPosts() {
        StudentPosts.sharedInstance.posts.removeAll()
    }
    
    static func generatePostsFromData(postData: [NSDictionary]) {
        for post in postData {
            if let post = post as? [String: AnyObject] {
                StudentPosts.sharedInstance.posts.append(StudentInformation(dictionary: post))
            }
        }
    }
    
    private init() { }
}