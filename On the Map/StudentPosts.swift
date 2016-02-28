//
//  StudentPosts.swift
//  On the Map
//
//  Created by Michael Miller on 2/19/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation

//this model class was created for the purpose of holding a singleton shared data model across view controllers; this class has a single public property that holds an array of studentInformation objects (all the data from the downloaded posts), and it from this array that the map annotations are created and the rows in the table are populated
class StudentPosts {
    
    static let sharedInstance = StudentPosts()
    var posts = [StudentInformation]()
    
    ///class method that is used to remove all the posts from the shared data model, which is used when a post is made and the data needs to be refresehd (i.e. downloaded again and stored again) for the map and the table
    static func clearPosts() {
        StudentPosts.sharedInstance.posts.removeAll()
    }
    
    ///class method that takes an array of NSDictionaries (as retrieved from parse and passed back to the caller through the client's retrieveStudentInformation method), and builds the shared "posts" property by taking each raw data post as returned from parse, casting it to a [String: AnyObject] dictionary, and appending it to the posts array as a new StudentInformation object, which is created using the dictionary-based initializer (as required by the project's specifications); this method completes when all raw posts have been converted to dictionaries and appended to the posts array, thus completing the data model for this app; as a note, the dictionary type was chosen to be [String: AnyObject] instead of [String: String] since there are two values that come from parse - the latitute and longitude - that do NOT get converted to strings, but rather floats 
    static func generatePostsFromData(postData: [NSDictionary]) {
        for post in postData {
            if let post = post as? [String: AnyObject] {
                StudentPosts.sharedInstance.posts.append(StudentInformation(dictionary: post))
            }
        }
    }
    
    private init() { }
}