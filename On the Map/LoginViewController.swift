//
//  ViewController.swift
//  On the Map
//
//  Created by Michael Miller on 2/10/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    struct Constants {
        static let LoginSegueIdentifer = "LoginSuccessfulSegue"
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
        
        dispatch_async(dispatch_get_main_queue()) {  //dispatching to main queue was needed here since the facebookManager presents UI and sometimes the presented loging window would dismiss AFTER the segue occurred, and that created a problem with the navigation view controller being presented on a view that was not in the hierarchy
            
            Client.facebookManager.logInWithReadPermissions(["public_profile"], fromViewController: self) { [unowned self] (loginResult, error) -> Void in
                if error == nil {
                    if !loginResult.isCancelled {
                        self.udacityClient.createUdacitySesssionFromFacebook(loginResult.token.tokenString) { (success, error) in
                            print("logged in")
                            self.completeLogin(success, error: error)
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
    
    
    func logoutOfFacebook() {
        Client.facebookManager.logOut()
        updateFacebookButton()
    }
    
    func updateFacebookButton() {
        if Client.facebookToken == nil {
            facebookLoginButton.setTitle("Login with Facebook", forState: .Normal)
            facebookLoginButton.removeTarget(self, action: "logoutOfFacebook", forControlEvents: .TouchUpInside)
            facebookLoginButton.addTarget(self, action: "loginWithFacebook", forControlEvents: .TouchUpInside)
        } else {
            facebookLoginButton.setTitle("Logout of Facebook", forState: .Normal)
            facebookLoginButton.removeTarget(self, action: "loginWithFacebook", forControlEvents: .TouchUpInside)
            facebookLoginButton.addTarget(self, action: "logoutOfFacebook", forControlEvents: .TouchUpInside)
        }
    }
    
    @IBAction func registerForUdacity(sender: UIButton) {
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        errorLabel.text = ""
        updateFacebookButton()
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
    }
}

