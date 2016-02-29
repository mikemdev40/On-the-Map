//
//  ViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/10/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import SafariServices
import FBSDKCoreKit
import FBSDKLoginKit

//this class is used for the login screen, as constructed in the interface builder
class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: CONSTANTS
    struct Constants {
        static let LoginSegueIdentifer = "LoginSuccessfulSegue"
        static let udacitySignUpURL = "https://www.udacity.com/account/auth#!/signup"
        static let loginErrorMissingInfoTitle = "Missing Info"
        static let loginErrorMissingInfoMessgae = "Username or password missing."
        static let loginWasCancelledTitle = "Login Not Successful"
        static let loginWasCancelledMessage = "Facebook login cancelled."
        static let generalLoginErrorTitle = "Login Error"
    }
    
    //MARK: OUTLETS
    @IBOutlet weak var usernameTextField: UITextField! {
        didSet { usernameTextField.delegate = self }
    }
    
    @IBOutlet weak var passwordTextField: UITextField! {
        didSet { passwordTextField.delegate = self }
    }
    
    @IBOutlet weak var udacityTitleLabel: UILabel!
    @IBOutlet weak var udacityLoginButton: UIButton!
    @IBOutlet weak var facebookLoginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //MARK: PROPERTIES
    //this property is used to store the (success, error) results from Client.createUdacitySesssionFromFacebook; these results are used later to pass into the completeLogin method, once it is determined that login has been successful and that the segue ot the tab bar view controller (with map and table) is safe to proceed
    var facebookLoginResults: (Bool, String?)?
    
    //the three properties below were implemented to monitor "readiness to segue" after having logged in with facebook (which was presenting some timing challenges due to some inconsistency with when the facebook login manager was dismissing the safari view controller after a successful login); when all three are true, the LoginSuccessfulSegue segue is deemed ready to take place; each variable is set at a different time, and each time one is set to either true or false, the "determineIfSegueCanHappen" gets called as part of the didSet property observer, which checks to see if all three are true; if all three are true (as well as if other conditions are met, as described in more detail in the method below), the "completeLogin" occurs, which checks to see if "success" is true (either from the facebook login or the traditional username/password login) and if so, allows the segue to take place; the reason it was necessary to monitor certain aspects of the login process before segueing came about specifically as a result of a timing issue with the facebook login process - when the user taps the login with facebook button and the facebook manager opens up a safari window, the modal view presented by the facebook SDK SOMETIMES returned back to the login screen before the completion handler was finished (and token active), and other times AFTER, which caused issues with automatically enabling the segue to occur when login was true; thus, the three properties monitor whether the login view controller is active (i.e. the facebook SDK has dismissed the safari window), that the facebook loading completed (i.e. the logInWithReadPermissions method returned, regardless of whether it was successful or not), and that the login to udactity using the facebook token completed (again, regardless of result)
    
    //this property is set true when the view appears (of particular importance is when the view reappears after having returned from facebook login window), and false when it disappears (of importance is when the facebook login button is tapped and the facebook login screen appears)
    var loginViewActive = false {
        didSet { determineIfSegueCanHappen() }
    }
    
    //this property is set to true when the completion handler of the Client.facebookManager.logInWithReadPermissions method is called (regardless of if it was successful or not)
    var facebookLoadedComplete = false {
        didSet { determineIfSegueCanHappen() }
    }
    
    //this proerty is set to true when the completion handler of the Client.createUdacitySesssionFromFacebook method is called (also regardless of if it was successful or not)
    var facebookLoginToUdacityComplete = false {
        didSet { determineIfSegueCanHappen() }
    }

    //MARK: CUSTOM METHODS
    ///method that performs the udacity login routine and is connected to the "Login to Udacity" button (see viewDidLoad for setup of this button); when tapped, a check to ensure something is typed into both fields (if not, an error alert is displayed), and if so, all buttons/fields are disabled (thus graying them out, by sending "true" to the custom disableViewsDuringLogin method), a spinner is started, and a call is made to the Client.createUdacitySession method, passing the username and password as arguments, as well as a completion that calls the "completeLogin" method with the results
    func loginToUdacity() {
        if checkForCompleteTextFields() {
            disableViewsDuringLogin(true)
            spinner.startAnimating()
            Client.createUdacitySession(username: usernameTextField.text!, password: passwordTextField.text!) {[unowned self] (success, error) -> Void in
                self.completeLogin(success, errorMessage: error, errorTitle: Constants.generalLoginErrorTitle)
            }
        } else {
            displayLoginErrorAlert(Constants.loginErrorMissingInfoTitle, message: Constants.loginErrorMissingInfoMessgae, handler: nil)
            //clears the cursor from both fields after the error is displayed
            passwordTextField.resignFirstResponder()
            usernameTextField.resignFirstResponder()
        }
    }
    
    ///method that performs the login with facebook routine and is connected to the "Login with Facebook" button (see viewDidLoad for setup of this button); when tapped, all buttons/fields are disabled (thus graying them out, by sending "true" to the custom disableViewsDuringLogin method), a spinner is started, and a check is made to see if a current facebook token exists on the device; if the current facebook token is nil (e.g. this is the first time logging in with facebook, or the user tapped the "logout" button in the previous session after having logged in with facebook), then a new facebook session is created through using the facebook manager's login method, which takes the user to a safari screen on which they must login and/or authenticate the app to use facebook; if there was no error and the user didn't cancel out of the screen, the token's "tokenString" representation is extracted from the result and passed to the Client.createUdacitySesssionFromFacebook method to complete the login (if successful, the results are saved for later use in the determineIfSegueCanHappen method); if a facebook token already currently exists on the system (i.e. one was saved from a previous login from facebook in which the user quit the app without logging out), then the token's "tokenString" representation is extracted from the result and passed to the Client.createUdacitySesssionFromFacebook method to complete the login, without having to authenticate through facebook again (i.e. the user is not taken to a safari screen); notably, it is in this method that TWO of the three "ready for segue" variables are set during the process by which a new token is created, since it the timing around going to a safari screen and coming back after a token is successfully created; at line 93, these two variables are now true, and the third is set to true when the login view controller again becomes active through within the viewDidAppear method (i.e. the safari screen has completely gone away), at which point, when the determineIfSegueCanHappen as part of the didSet property observer, the first line of that method is true and the segue can then continue on (this prevented the segue from getting called before the safari view had completely been dismissed by the facebook SDK, or before the token had been completely retrieved and udactity session created from it)
    func loginWithFacebook() {
        disableViewsDuringLogin(true)
        spinner.startAnimating()

        if Client.facebookToken == nil {
            Client.facebookManager.logInWithReadPermissions(["public_profile"], fromViewController: self) { [unowned self] (loginResult, error) -> Void in
                if error == nil {
                    self.facebookLoadedComplete = true  //first of three "ready for segue" variables
                    if !loginResult.isCancelled {
                        Client.createUdacitySesssionFromFacebook(loginResult.token.tokenString) { (success, error) in
                            self.facebookLoginResults = (success, error)
                            self.facebookLoginToUdacityComplete = true  //second of three "ready for segue" variables
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.completeLogin(false, errorMessage: Constants.loginWasCancelledMessage, errorTitle: Constants.loginWasCancelledTitle)
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.completeLogin(false, errorMessage: error.localizedDescription, errorTitle: Constants.generalLoginErrorTitle)
                    }
                }
            }
        } else {
            if let tokenString = Client.facebookToken?.tokenString {
                    Client.createUdacitySesssionFromFacebook(tokenString) { (success, error) in
                    self.completeLogin(success, errorMessage: error, errorTitle: Constants.generalLoginErrorTitle)
                }
            }
        }
    }
    
    ///method that gets called each time one of the three "ready for segue" variables is set to a new value, which check the value of all three, and once all are true (two are set in the loginWithFacebook method and the third is set in the viewDidAppear), the facebook login results are checked to ensure they exist (i.e. non-nil), the three "ready to segue" variables are set back to false, and the completeLogin method is called, with the results and error elements of the facebookLoginResults tuple being passed as parameters (whether the login was actually successful is checked as part of the completeLogin method)
    func determineIfSegueCanHappen() {
        if loginViewActive && facebookLoadedComplete && facebookLoginToUdacityComplete {
            if let loginResults = facebookLoginResults {
                loginViewActive = false
                facebookLoadedComplete = false
                facebookLoginToUdacityComplete = false
                completeLogin(loginResults.0, errorMessage: loginResults.1, errorTitle: Constants.generalLoginErrorTitle)
            }
        }
    }

    ///method that gets called from both udacity login pathways (the username/password pathway and the login with facebook pathway), taking the boolean result of the login and error message (if there is any) as parameters, and if "success" is true, re-enables all the buttons/fields (by sending "false" to the custom disableViewsDuringLogin method), then performs the actual segue that takes the user to the first of two view controllers within a tab bar structure; if "success" is false, then the login screen is brought back to its original state (all fields/buttons enabled and no spinner), and an error message is shown with the error string that has been passed along through the login process; in order to arrive at this method through the facebook login pathway, all three "ready to segue" variables need to be true, which then allows the determineIfSegueCanHappen to call this method (the traditional username/password pathway bypasses this additional checking, and calls this method as part of the createUdacitySession completion handler)
    func completeLogin(success: Bool, errorMessage: String?, errorTitle: String?) {
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                self.disableViewsDuringLogin(false)
                self.performSegueWithIdentifier(Constants.LoginSegueIdentifer, sender: nil)
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.disableViewsDuringLogin(false)
                self.spinner.stopAnimating()
                if let errorMessage = errorMessage, let errorTitle = errorTitle {
                    self.displayLoginErrorAlert(errorTitle, message: errorMessage, handler: nil)
                }
            }
        }
    }
    
    ///method that is attached directly to the "Need to Sign Up for Udacity" button via the interface builder; when tapped, an NSURL is generated from the udacity sign up URL, and a safari view controller is created using the URL and presented to the user
    @IBAction func registerForUdacity(sender: UIButton) {
        if let signupURL = NSURL(string: Constants.udacitySignUpURL) {
            let signUpViewContoller = SFSafariViewController(URL: signupURL)
            presentViewController(signUpViewContoller, animated: true, completion: nil)
        }
    }
    
    ///method that displays an alert to the user with single "OK" button (used to indicate both errors and successes), and takes a title string, message string, and optional completion handler; as a note, i reused this method directly from another project and left the optional completion handler as part of the structure, even though none of the calls to this method within this app utilize a completion handler (i.e. all calls pass in nil for the third argument)
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    ///method that disables (or re-enables) the various views on the login screen, which is called throughout the login process for the purpose of graying out all the fields/buttons when logging in is occurring, in addition to preventing the user from interacting with anything while the login process is going on; a call to this method with "true" as the argument will disable all views, and a call to this method with "false" will enable the views; notably, because custom buttons by default don't "appear" disabled (i.e. grayed out) when they are disabled, it was necesary to also reduce the alpha of the two colored buttons when they were disabled to give the visual appearance of disabled
    func disableViewsDuringLogin(disabled: Bool) {
        udacityLoginButton.enabled = !disabled
        udacityLoginButton.alpha = !disabled ? 1.0 : 0.25
        facebookLoginButton.enabled = !disabled
        facebookLoginButton.alpha = !disabled ? 1.0 : 0.25
        usernameTextField.enabled = !disabled
        passwordTextField.enabled = !disabled
        registerButton.enabled = !disabled
    }
    
    //method that checks both text fields to see if there is something typed in each one (returning "true" if both fields have something typed in them, and false if one or both is empty)
    func checkForCompleteTextFields() -> Bool {
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            return false
        } else {
            return true
        }
    }
    
    //MARK: DELEGATE/DATASOURCE METHODS
    //this delegate method causes the keyboard to dismiss when the user taps "return" on the text field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: VIEW CONTROLLER METHODS
    //this method is used in this app for the purpose of dismissing the keyboard when the user taps anyone on the screen that is not in the textfield
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    //this method is invoked when performSegueWithIdentifer is called, which occurs strictly within the completeLogin method; within this segue setup, a variable is set to the navigation controller (in which the tab bar controller is embedded), which is the technical destination of the segue, and then grabs a hold of the tab bar controller by accessing the navigation controller's viewControllers property and getting the root view controller, [0], then casting it as the custom TabBarViewController subclass for the purpose of setting its activity spinner to a reference to the spinner on the login view (so the spinner can be turned off when logout occurs)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.LoginSegueIdentifer {
            var destinationViewController = segue.destinationViewController
            if let navigationViewController = destinationViewController as? UINavigationController {
                destinationViewController = navigationViewController.viewControllers[0]
                if let tabBarController = destinationViewController as? TabBarViewController {
                    tabBarController.spinner = spinner
                }
            }
        }
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    //in the viewDidAppear/Disappear methods, the third "ready for segue" variable is set as a way to monitor when the facebook login pathway brings up a safari view controller (via the facebook SDK's login manager), and when the safari view gets dismiised by the login manager
    override func viewDidAppear(animated: Bool) {
        loginViewActive = true  //third of three "ready for segue" variables
    }
    
    override func viewDidDisappear(animated: Bool) {
        loginViewActive = false
    }
    
    //in this method, two of the buttons and main udacity text are set up and attached to their respective functions; i got the colors by researching "facebook blue" for the facebook button, and using a color picker on the uadacity logo to get an appropriately close orange
    override func viewDidLoad() {
        super.viewDidLoad()
                
        spinner.hidesWhenStopped = true

        udacityTitleLabel.textColor = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1.0)
        
        udacityLoginButton.backgroundColor = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1.0)
        udacityLoginButton.layer.cornerRadius = 7
        udacityLoginButton.addTarget(self, action: "loginToUdacity", forControlEvents: .TouchUpInside)
        
        facebookLoginButton.backgroundColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0)
        facebookLoginButton.layer.cornerRadius = 7
        facebookLoginButton.addTarget(self, action: "loginWithFacebook", forControlEvents: .TouchUpInside)
    }
}

