//
//  TabBarViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    
    func logout() {
        Client.logout { (success, error) in
            if success {
                print("successfully logged out")
            } else {
                print(error)
            }
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On the Map"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logout")
        
    }

}
