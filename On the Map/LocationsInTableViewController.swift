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

    //MARK: CONSTANTS
    struct Constants {
        static let openPostViewSegue = "SegueFromTableToPost"
    }
    
    //MARK: OUTLETS
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    //MARK: PROPERTIES
    //this property establishes the "pull down to refresh" feature of the table view; although this is a feature that is a pre-defined property of a UITableViewController, it is possible to manually add it (as done here) for view controllers that are not subclasses of UITableViewController; however, the set up (as accomplished in the viewDidLoad) needed a bit of research to get it work correctly (because, as promised in the documentation, it was at first exhibiting unexpected behavior!)
    let refresher = UIRefreshControl()

    //MARK: CUSTOM METHODS
    ///method that is associated with the post button in the navigation bar; the tab bar class itself is responsible for setting the target of the post button to be this view controller, at which point, this post method is the action that runs when the post button is pressed
    func post() {
        performSegueWithIdentifier(Constants.openPostViewSegue, sender: self)
    }

    ///method that is associated with the refresh button in the navigation bar (and as with the post button, the tab bar class itself is responsible for setting the target of the refresh button to be this view controller, at which point, this refresh method is the action that runs when the refresh button is pressed), and ALSO attached as the action associated with the UIRefreshControl; when this method is invoked (regardless of if it was the refresh button that was tapped or the table pulldown refresh method), the refresher starts refreshing (which is visible only if the table was pulled down to start the refreshing), the network indicator starts spinning to show network activity, all posts are cleared out to be re-downloaded (if this method is running for the very first time, there is nothing to clear out), and a call is made to the Client.retrieveStudentInformation method, which is responsible for downloading all the post data from parse; if there are results (and no error) to display, then a call is made to the StudentPosts.generatePostsFromData, which builds the array from all the post data that the table uses as the datasource for its cells, and then refreshes the table
    func refresh() {
        refresher.beginRefreshing()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        StudentPosts.clearPosts()
        Client.retrieveStudentInformation { (success, error, results) in
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if error != nil {
                    self.refresher.endRefreshing()
                    self.displayLoginErrorAlert("Error", message: error!, handler: nil)
                } else if let results = results {
                    StudentPosts.generatePostsFromData(results)
                    self.tableView.reloadData()
                    self.refresher.endRefreshing()
                }
            }
        }
    }
    
    ///method that displays an alert to the user with single "OK" button (used to indicate both errors and successes), and takes a title string, message string, and optional completion handler; as a note, i reused this method directly from another project and left the optional completion handler as part of the structure, even though none of the calls to this method within this app utilize a completion handler (i.e. all calls pass in nil for the third argument)
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    ///helper method that takes a JSON-coded date (such as "2012-04-23T18:25:43.511Z") and returns the first 10 characters (which constitute the date) as a string; since all that was needed was a string representation of the post date for use in a cell label, there was no need to do anything with NSDate or anything, which made getting the date much easier
    func getDateFromString(dateStringToConvert: String) -> String {
        let newString = dateStringToConvert.substringToIndex(dateStringToConvert.startIndex.advancedBy(10))
        return newString
    }

    //MARK: DELEGATE/DATASOURCE METHODS
    //this datasource method build each custom PostTableViewCell (as laid out in the interface builder) by getting data from the shared StudentPosts.sharedInstance.posts singleton data source (which is built up in the refresh method), and assiging the four labels the string values that are a saved in each StudentInformation post object
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! PostTableViewCell
        let postToShow = StudentPosts.sharedInstance.posts[indexPath.row]
        
        cell.nameLabel.text = postToShow.firstName + " " + postToShow.lastName
        cell.urlLabel.text = postToShow.mediaURL
        cell.locationLabel.text = postToShow.mapString
        cell.dateLabel.text = getDateFromString(postToShow.updatedAt)
        
        return cell
    }
    
    //this datasource method (which generally isn't needed for table implementation) that returns for each row whether it can be edited (i.e. deleted) is used in this app specifcally to denote ONLY the user's post as "ok to delete"; by comparing the "uniqueKey" value of the specific post to the logged in udacity user's udacity ID, only the posts that show a match between the two (i.e. the posts made by the logged in user) will get a delete icon next to them when the table goes into edit mode
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        //gets the udacity user ID from the post at the specific row
        let postUserId = StudentPosts.sharedInstance.posts[indexPath.row].uniqueKey
        
        //checks to see if the udacity user ID of the post matches the udacity ID of the logged in user; if so, that cell CAN be edited (specifically deleted) in edit mode, and if not, then there is no delete button that appears
        if postUserId == Client.udacityUserID {
            return true
        } else {
            return false
        }
    }
    
    //this datasource method responds to a delete command (which can only be performed on posts that the logged in user owns) by getting the objectID from that post (which is the unique ID that is set automatically by the parse server when the post is created on the server), and making a call to the Client.deletePost method which actually performs the delete on the parse server; if the delete was successful, then the table is automatically refreshed (all posts removed from the shared data source, then re-added); as an added note, within the Client.deletePost method, the didDeleteItem is set to true when the delete is successful which is used by the map view controller to check (when the user switches to it) and perform another refresh so that it also has the most recent data without the deleted post
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        //as i learned, .Delete is set as the default editing style for each cell if the editingStyleForRowAtIndexPath method isn't implemented by the delegate (as discussed in the documentation for the tableView:editingStyleForRowAtIndexPath: delegate method)
        if editingStyle == .Delete {
            
            let objectIdToDelete = StudentPosts.sharedInstance.posts[indexPath.row].objectID
            
            Client.deletePost(objectIdToDelete, completionHandler: { [unowned self] (success, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    if let error = error {
                        self.displayLoginErrorAlert("Error", message: error, handler: nil)
                    } else {
                        self.refresh()
                    }
                })
            })
        }
    }
    
    //this delegate method opens up the associated URL when the row is tapped by the user by opening up a safari window using the URL-based initilizer of the SFSafariViewController class; because there are currently issues with opening up URLs using the SFSafariViewController class that do not start with a proper scheme (e.g. http or https, as discussed here http://stackoverflow.com/questions/32864287/sfsafariviewcontroller-crashing-on-valid-nsurl ), the method checks to first see if the scheme contains either of those prefixes, and if so, it launches the safari view controller, and if NOT, then an "http://" prefix is attached (i got this idea from the stackoverflow post); once the user is done navigating the safari window, clicking the "Done" button in the top left will bring them back to the table view
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
    
    //this datasource method simply sets the number of rows in the table to be equal to the number of posts in the shared data source
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentPosts.sharedInstance.posts.count
    }
    
    //MARK: VIEW CONTROLLER METHODS
    //this method gets invoked by the tab view controller's edit button, as detailed in the TabBarViewController class, so as to link the tab bar's editing mode that the edit button is actually toggling to this view controller's editing mode and then finally to the table view's editing mode (NOTE: if this view controller was instead a UITableViewController and the edit button was attached to the UITableViewController's navigation bar rather than a tab bar controller's navigvation bar, then the edit button would automatically toggle the table without these two intermediate steps; however, the overridden method below is needed because we are dealing with a table view as a SUBVIEW of a generic UIViewController's root view - and not the table view of a UITableViewController [which is that controller's root view], and the overridden setEditing method in the tab bar controller is needed because the navigation bar itself is associated with the tab bar, and so the editing button is actually toggling the tab bar's setEditing mode; needless to say, getting this to work correctly was tricky and frustrating!)
    override func setEditing(editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: true)
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    //when the view is about to appear, either from the MakePostViewController being dismissed (if the table was the tab the user was on when the post button was tapped) or from switching from the map view, there is a quick check to the second element of the Client.didPostItem tuple (the element designated for the table view controller) to see if a new post has been made since the table view was last seen; if so, the table is refreshed so as to capture on the table any new post by the user (and any others that may have been made by other udacity users during that time)
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if Client.didPostItem.1 {
            refresh()
            Client.didPostItem.1 = false
        }
    }
    
    //then the view loads, the UIRefreshControl is set up and inserted into the table view in a way that enabled proper functioning when the user pulls the table down
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresher.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        refresher.attributedTitle = NSAttributedString(string: "Retrieving updated posts!")
        
        //although my first attempt to add the refresher to the table was via tableView.addSubview(refresher), using the addSubview method on the table view results in the refresher being visible through the tableview for a split second when the refresher ends refreshing, but using the insertSubview method below prevents that, per http://stackoverflow.com/questions/12497940/uirefreshcontrol-without-uitableviewcontroller?lq=1
        tableView.insertSubview(refresher, atIndex: 0)
    }
}
