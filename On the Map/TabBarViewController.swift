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
    var logoutButton: UIBarButtonItem!
    var refreshButton: UIBarButtonItem!
    var postButton: UIBarButtonItem!
    
    func logout() {
        spinner?.stopAnimating()
        
        logoutButton.enabled = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        if Client.facebookToken != nil {
            Client.logoutOfFacebook()
        }
        Client.logoutOfUdacity { (success, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func post() {
        print("post")
        print(selectedViewController?.title)
    }
    
    func refresh() {
        print("reresh")
        print(selectedViewController?.title)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "On The Map"
        logoutButton = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logout")
        navigationItem.leftBarButtonItem = logoutButton
        
        refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refresh")
        postButton = UIBarButtonItem(image: UIImage(named: "pin"), style: .Plain, target: self, action: "post")
        navigationItem.rightBarButtonItems = [refreshButton, postButton]
        
        viewControllers?[0].tabBarItem.image = UIImage(named: "map")
        viewControllers?[0].title = "Map"
        viewControllers?[1].tabBarItem.image = UIImage(named: "list")
        viewControllers?[1].title = "List"
    }

}
