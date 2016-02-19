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

class LoginViewController: UIViewController, UITextFieldDelegate {

    struct Constants {
        static let LoginSegueIdentifer = "LoginSuccessfulSegue"
        static let udacitySignUpURL = "https://www.udacity.com/account/auth#!/signup"
        static let loginErrorMissingInfoTitle = "Missing Info"
        static let loginErrorMissingInfoMessgae = "Username or password missing."
        static let loginWasCancelledTitle = "Login Not Successful"
        static let loginWasCancelledMessage = "Facebook login cancelled."
        static let generalLoginErrorTitle = "Login Error"
    }
    
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
    
    var facebookLoginResults: (Bool, String?)?
    var loginViewActive = false {
        didSet { determineIfSegueCanHappen() }
    }
    var facebookLoadedComplete = false {
        didSet { determineIfSegueCanHappen() }
    }
    
    var facebookLoginToUdacityComplete = false {
        didSet { determineIfSegueCanHappen() }
    }

    func loginToUdacity() {
        if checkForCompleteTextFields() {
            disableViewsDuringLogin(true)
            spinner.startAnimating()
            Client.createUdacitySession(username: usernameTextField.text!, password: passwordTextField.text!) {[unowned self] (success, error) -> Void in
                self.completeLogin(success, errorMessage: error, errorTitle: Constants.generalLoginErrorTitle)
            }
        } else {
            displayLoginErrorAlert(Constants.loginErrorMissingInfoTitle, message: Constants.loginErrorMissingInfoMessgae, handler: nil)
            passwordTextField.resignFirstResponder()
            usernameTextField.resignFirstResponder()
        }
    }
    
    func loginWithFacebook() {
        disableViewsDuringLogin(true)
        spinner.startAnimating()
        
        //if a facebook token currently exists on the system (i.e. one was saved from a previous login from facebook in which the user quit the app without logging out), then the udacity session is created using the token without having to authenticate through facebook again and the login segue occurs; if the current facebook token is nil (e.g. first time logging in with facebook, or the user tapped the "logout" button in the previous session after having logged in with facebook), then an extra step is required in which the user goes to the facebook authentication page first before the login segue occurs
        if Client.facebookToken == nil {
            Client.facebookManager.logInWithReadPermissions(["public_profile"], fromViewController: self) { [unowned self] (loginResult, error) -> Void in
                if error == nil {
                    self.facebookLoadedComplete = true
                    if !loginResult.isCancelled {
                        Client.createUdacitySesssionFromFacebook(loginResult.token.tokenString) { (success, error) in
                            self.facebookLoginResults = (success, error)
                            self.facebookLoginToUdacityComplete = true
                        }
                    } else {
                        self.completeLogin(false, errorMessage: Constants.loginWasCancelledMessage, errorTitle: Constants.loginWasCancelledTitle)
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
    
    @IBAction func registerForUdacity(sender: UIButton) {
        if let signupURL = NSURL(string: Constants.udacitySignUpURL) {
            let signUpViewContoller = SFSafariViewController(URL: signupURL)
            presentViewController(signUpViewContoller, animated: true, completion: nil)
        }
    }
    
    func displayLoginErrorAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func disableViewsDuringLogin(disabled: Bool) {
        udacityLoginButton.enabled = !disabled
        udacityLoginButton.alpha = !disabled ? 1.0 : 0.25
        facebookLoginButton.enabled = !disabled
        facebookLoginButton.alpha = !disabled ? 1.0 : 0.25
        usernameTextField.enabled = !disabled
        passwordTextField.enabled = !disabled
        registerButton.enabled = !disabled
    }
    
    func checkForCompleteTextFields() -> Bool {
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            return false
        } else {
            return true
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
    }
    
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
    
    override func viewDidAppear(animated: Bool) {
        loginViewActive = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        loginViewActive = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }
    
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

