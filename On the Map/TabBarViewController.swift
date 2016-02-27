//
//  TabBarViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    var spinner: UIActivityIndicatorView?
    var logoutButton: UIBarButtonItem!
    var refreshButton: UIBarButtonItem!
    var postButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var flexibleSpace: UIBarButtonItem!
        
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
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        refreshButton.target = selectedViewController
        postButton.target = selectedViewController
        
        if selectedViewController === viewControllers?[1] {
            editButton.enabled = true
        } else {
            editButton.enabled = false
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        viewControllers?[1].setEditing(editing, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        
        title = "On The Map"
        flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

        logoutButton = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logout")
        editButton = editButtonItem()
        editButton.enabled = false
        navigationItem.leftBarButtonItems = [logoutButton, flexibleSpace, editButton, flexibleSpace]
        
        refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: viewControllers?[0], action: "refresh")
        postButton = UIBarButtonItem(image: UIImage(named: "pin"), style: .Plain, target: viewControllers?[0], action: "post")
        navigationItem.rightBarButtonItems = [refreshButton, flexibleSpace, postButton, flexibleSpace]
        
        viewControllers?[0].tabBarItem.image = UIImage(named: "map")
        viewControllers?[0].title = "Map"
        viewControllers?[1].tabBarItem.image = UIImage(named: "list")
        viewControllers?[1].title = "List"
    }
}
