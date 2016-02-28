//
//  TabBarViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    //MARK: PROPERTIES
    //this property is set within the segue from the login view controller
    var spinner: UIActivityIndicatorView?
    
    //these properties defined the buttons that will appear on the navigation bar; since the bar button items are being defined in the tab bar view controller's class, these buttons will then appear on top of each tab bar view controller, as the map and table view controllers utilize the same navigation bar as the tab bar controller (since they aren't each embedded in their own separate navigation controllers)
    var logoutButton: UIBarButtonItem!
    var refreshButton: UIBarButtonItem!
    var postButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var flexibleSpace: UIBarButtonItem!
    
    //MARK: CUSTOM METHODS
    ///this method is attached to the "logout" button in the top left (see viewDidLaod for setup of this button) and stops the spinner on the login page (since the user is about to be returned there), disables the logout button while the logout occurs, turns on the network activity icon in the status bar while the logout occurs, then logs the user out of facebook (if there is a facebook token active) by calling the Client.logoutOfFacebook method (which simply calls the facebook manager's logOut method), and finally logs the user out of udacity by calling the Client.logoutOfUdacity method, which sends a delete session message to the udacity server; note that, regardless of the logout response from udacity, the network spinner is stopped and the view controller is dismissed, returning the user to the main login page
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
    
    //MARK: VIEW CONTROLLER METHODS
    //since both view controllers are utilizing the same navigation bar buttons, but the buttons themselves, when pressed, need to invoke specific methods on that view controller; when a tab is selected, the refresh button's target is set to that view controller, which means that the "refresh" action method on THAT view controller will be invoked, and the same with the post button; both view controller classes have a "refresh" method and a "post" method defined in their classes, so by switching the target of these two navigation bar buttons to match the currently selected tab bar view controller, it is possible to customize these two methods for the view controllers; additionally, in this method, the "edit" button is toggled on and off, depending on which tab bar item is selected, since i only designed the "edit mode" to be possible in the table view tab (since only there the user has the ability to delete posts)
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        refreshButton.target = selectedViewController
        postButton.target = selectedViewController
        
        if selectedViewController === viewControllers?[1] {
            editButton.enabled = true
        } else {
            editButton.enabled = false
        }
    }
    
    //this override is required so that the "editing" value of the edit button, which is attached to ths tab bar class, is passed to the table view controller so that it is possile to use the edit button to enable the edit view on the table cells
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        viewControllers?[1].setEditing(editing, animated: true)
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    //in this method, the tab bar sets itself as its own delegate, as it wants to be aware of when the user chooses a different tab (didSelectViewController is a delegate method) and respond accordingly; the setup of the navigation bar items on the left and right also happens here, as well as naming the tab bar item buttons and assigning the images to the tab buttons
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
