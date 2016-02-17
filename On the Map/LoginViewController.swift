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
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var udacityClient = Client()
    
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
            udacityClient.createUdacitySession(username: usernameTextField.text!, password: passwordTextField.text!) {[unowned self] (success, error) -> Void in
                self.completeLogin(success, error: error)
            }
        } else {
            errorLabel.text = "Username or password missing."
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
                        self.udacityClient.createUdacitySesssionFromFacebook(loginResult.token.tokenString) { (success, error) in
                            print("token created, logged in")
                            self.facebookLoginResults = (success, error)
                            self.facebookLoginToUdacityComplete = true
                            print(self.facebookLoginResults)
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.errorLabel.text = "Login cancelled."
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.errorLabel.text = error.localizedDescription
                    }
                }
            }
        } else {
            if let tokenString = Client.facebookToken?.tokenString {
                self.udacityClient.createUdacitySesssionFromFacebook(tokenString) { (success, error) in
                    print("token already active, logged in")
                    self.completeLogin(success, error: error)
                }
            }
        }
    }
    
    func determineIfSegueCanHappen() {
        if loginViewActive && facebookLoadedComplete && facebookLoginToUdacityComplete {
            print("ALMOST MADE IT")
            print(facebookLoginResults)
            if let loginResults = facebookLoginResults {
                print("MADE IT")
                completeLogin(loginResults.0, error: loginResults.1)
                loginViewActive = false
                facebookLoadedComplete = false
                facebookLoginToUdacityComplete = false
            }
        }
    }

    func completeLogin(success: Bool, error: String?) {
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                self.disableViewsDuringLogin(false)
                self.performSegueWithIdentifier(Constants.LoginSegueIdentifer, sender: nil)
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.disableViewsDuringLogin(false)
                self.errorLabel.text = error
            }
        }
    }
    
    @IBAction func registerForUdacity(sender: UIButton) {
        if let signupURL = NSURL(string: Constants.udacitySignUpURL) {
            let signUpViewContoller = SFSafariViewController(URL: signupURL)
            presentViewController(signUpViewContoller, animated: true, completion: nil)
        }
    }
    
    func disableViewsDuringLogin(disabled: Bool) {
        errorLabel.text = ""
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
        errorLabel.text = ""
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.LoginSegueIdentifer {
            var destinationViewController = segue.destinationViewController
            if let navigationViewController = destinationViewController as? UINavigationController {
                destinationViewController = navigationViewController.viewControllers[0]
                if let tabBarController = destinationViewController as? TabBarViewController {
                    tabBarController.spinner = spinner
                    print("segue")
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        loginViewActive = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        errorLabel.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(Client.facebookToken)
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

