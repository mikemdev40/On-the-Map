//
//  TabBarViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    var spinner: UIActivityIndicatorView?
    
    func logout() {
        spinner?.stopAnimating()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        if Client.facebookToken != nil {
            Client.logoutOfFacebook()
        }
        Client.logoutOfUdacity { (success, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On the Map"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logout")
        
    }

}
