//
//  LocationsInTableViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/11/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import SafariServices

class LocationsInTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    func post() {
        print("post TABLE")
    }
    
    func refresh() {
        print("refresh TABLE")

        StudentPosts.clearPosts()
        
        Client.retrieveStudentInformation { (success, error, results) in
            if error != nil {
                self.displayLoginErrorAlert("Error", message: error!, handler: nil)
            } else if let results = results {
                StudentPosts.generatePostsFromData(results)
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! PostTableViewCell
        let postToShow = StudentPosts.sharedInstance.posts[indexPath.row]
        
        cell.nameLabel.text = postToShow.firstName + " " + postToShow.lastName
        cell.urlLabel.text = postToShow.mediaURL
        cell.locationLabel.text = postToShow.mapString
        cell.dateLabel.text = getDateFromString(postToShow.updatedAt)
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let mediaURL = StudentPosts.sharedInstance.posts[indexPath.row].mediaURL
        if let url = NSURL(string: mediaURL) {
            if ["http", "https"].contains(url.scheme.lowercaseString) {
                let safariViewController = SFSafariViewController(URL: url)
                presentViewController(safariViewController, animated: true, completion: nil)
            } else {
                let updatedURL = "http://" + mediaURL
                if let newNSURL = NSURL(string: updatedURL) {
                    let safariViewController = SFSafariViewController(URL: newNSURL)
                    presentViewController(safariViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentPosts.sharedInstance.posts.count
    }
    
    func getDateFromString(dateStringToConvert: String) -> String {
        let newString = dateStringToConvert.substringToIndex(dateStringToConvert.startIndex.advancedBy(10))
        return newString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
