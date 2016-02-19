//
//  LocationsInTableViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class LocationsInTableViewController: UIViewController {

    func post() {
        print("post TABLE")
    }
    
    func refresh() {
        print("reresh TABLE")
        print(StudentPosts.sharedInstance.posts[0])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
