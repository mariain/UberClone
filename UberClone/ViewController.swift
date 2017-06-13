//
//  ViewController.swift
//  UberClone
//
//  Created by Maria on 5/12/17.
//  Copyright © 2017 Maria Notohusodo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var rider: UILabel!
    @IBOutlet weak var driver: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        if username.text == "" || password.text == "" {
            displayAlert(title: "Missing Field(s)", message: "username and password are required")
        } else {
            if signUpState == true {
                let user = PFUser()
                user.username = username.text
                user.password = password.text
                user["isDriver"] = `switch`.isOn
                
                user.signUpInBackground { [weak self]
                    (succeeded, error) -> Void in
                    if let error = error {
                        if let errorString = (error as NSError).userInfo["error"] as? String
                        {
                            self?.displayAlert(title: "Sign up failed", message: errorString)}
                    } else {
                        if self?.`switch`.isOn == true {
                            self?.performSegue(withIdentifier: "loginDriver", sender: self)
                        } else {
                            self?.performSegue(withIdentifier: "loginRider", sender: self)
                        }
                    }
                }
            } else {
                PFUser.logInWithUsername(inBackground: username.text!, password:password.text!) { [weak self]
                    (user, error) -> Void in
                    if let user = user {
                        if user["isDriver"] as! Bool == true {
                            self?.performSegue(withIdentifier: "loginDriver", sender: self)
                        } else {
                            self?.performSegue(withIdentifier: "loginRider", sender: self)
                        }
                    } else {
                        if let errorString = (error as NSError?)?.userInfo["error"] as? String
                        {
                            self?.displayAlert(title: "Login failed", message: errorString)}
                    }
                }
            }
        }
    }
    @IBOutlet weak var toggleSignupButton: UIButton!
    
    @IBAction func toggleSignup(_ sender: UIButton) {
        if signUpState == true {
            signUpButton.setTitle("Login", for: .normal)
            toggleSignupButton.setTitle("Switch to signup", for: .normal)
            signUpState = false
            
            rider.alpha = 0
            driver.alpha = 0
            `switch`.alpha = 0
        } else {
            signUpButton.setTitle("Signup", for: .normal)
            toggleSignupButton.setTitle("Switch to login", for: .normal)
            signUpState = true
            
            rider.alpha = 1
            driver.alpha = 1
            `switch`.alpha = 1
        }
    }
    
    var signUpState = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        username.delegate = self
        password.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current()?.username != nil {
            if PFUser.current()?["isDriver"] as! Bool == true {
                performSegue(withIdentifier: "loginDriver", sender: self)
            } else {
                self.performSegue(withIdentifier: "loginRider", sender: self)
            }
        }
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

