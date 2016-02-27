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

    struct Constants {
        static let openPostViewSegue = "SegueFromTableToPost"
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    let refresher = UIRefreshControl()

    func post() {
        performSegueWithIdentifier(Constants.openPostViewSegue, sender: self)
    }
    
    func refresh() {
        refresher.beginRefreshing()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        StudentPosts.clearPosts()
        Client.retrieveStudentInformation { (success, error, results) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.refresher.endRefreshing()
                    self.displayLoginErrorAlert("Error", message: error!, handler: nil)
                }
            } else if let results = results {
                StudentPosts.generatePostsFromData(results)
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    self.refresher.endRefreshing()
                }
            }
        }
    }
    
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    //gets invoked by the tab view controller's edit button
    override func setEditing(editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: true)
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
        
        refresher.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        refresher.attributedTitle = NSAttributedString(string: "Retrieving updated posts!")
        //tableView.addSubview(refresher)
        tableView.insertSubview(refresher, atIndex: 0)   //using the addSubview method on the table view results in the refresher being visible through the tableview for a split second when the refresher ends refreshing, but using the insertSubview method prevents that, per http://stackoverflow.com/questions/12497940/uirefreshcontrol-without-uitableviewcontroller?lq=1
    }
}
