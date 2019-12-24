//
//  LoginViewController.swift
//  Snap-App
//
//  Created by Tushar Gusain on 12/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//Make a seperate api class for firebase Database

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    //MARK:- IBOutlets
    @IBOutlet var emailTextView: UITextField! {
        didSet {
            emailTextView.delegate = self
        }
    }
    @IBOutlet var passwordTextView: UITextField! {
           didSet {
               passwordTextView.delegate = self
           }
       }
    @IBOutlet var loginIndicator: UIActivityIndicatorView!
    
    //MARK:- Member Variables
    private let segueIdentifier = "ChatsList"
    var username = ""
    var user: User! 
    
    //MARK:- IBAction Methods
    @IBAction func login(_ sender: UIButton) {
        if let email = emailTextView.text,
            let password = passwordTextView.text,
            !email.isEmpty, !password.isEmpty {
            loginIndicator.isHidden = false
            FirebaseApi.shared.registerUser(email: email, password: password, isLogin: true) { [weak self] authResult, error, user in
                guard let self = self else { return }
                if let error = error {
                    self.alert(title: "Login Error", message: "\(error.localizedDescription)")
                    self.loginIndicator.isHidden = true
                } else{
                    self.alert(title: "Login Successful", message: "Logged in as \(user.username)")
                    self.user = user
                    print("user details after login:",self.user)
                    self.loginIndicator.isHidden = true
                    self.performSegue(withIdentifier: self.segueIdentifier, sender: self)
                    //handle is doing the job of getting the user details
                }
            }
        } else {
            alert(title: "Specify fields", message: "Please specify the Email or Password")
        }
    }
    @IBAction func signUp(_ sender: UIButton) {
        if let email = emailTextView.text,
        let password = passwordTextView.text,
            !email.isEmpty, !password.isEmpty {
            loginIndicator.isHidden = false
            FirebaseApi.shared.registerUser(email: email, password: password, isLogin: false) { [weak self] authResult, error, user in
                guard let self = self else { return }
                if let error = error {
                    self.alert(title: "SignUp Error", message: "\(error.localizedDescription)")
                    self.loginIndicator.isHidden = true
                } else{
                    self.user = user
                    print("User after signing up:",user)
                    self.loginIndicator.isHidden = true
                    self.showUsernameFillDialog()
                }
            }
        } else {
            self.alert(title: "Fill the details", message: "Please specify the Email id and Password")
        }
    }
    
    //MARK:- Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseApi.shared.initializeLoginStateChangeHandle() { [weak self] user in
            guard let self = self else {
                return
            }
            self.user = user
            print("user on state changed",user)
            if user.id != "" {
                self.performSegue(withIdentifier: self.segueIdentifier, sender: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FirebaseApi.shared.removeLoginStateChangeHandle()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            if let navVC = segue.destination as? UINavigationController {
                if let chatTableVC = navVC.viewControllers.first as? ChatTableViewController {
                    chatTableVC.user = user
                }
            }
        }
    }
    
    //MARK:- Custom Methods
    private func showUsernameFillDialog() {
        let alert = UIAlertController(title: "Signing you up...", message: "Please fill the username", preferredStyle: .alert)
        
        alert.addTextField { textField in
            let names = ["Ford", "Arthur", "Zaphod", "Trillian", "Slartibartfast", "Humma Kavula", "Deep Thought"]
            textField.text = names[Int(arc4random_uniform(UInt32(names.count)))]
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] alertAction in
            guard let self = self else {
                return
            }
            if let textField = alert.textFields?[0], !textField.text!.isEmpty {
                self.user.username = textField.text!
                FirebaseApi.shared.createUserInDB(user: self.user) {
                    self.alert(title: "Successfully Signed Up", message: "username: \(self.user.username)")
                    self.performSegue(withIdentifier: self.segueIdentifier, sender: self)
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

//MARK:- Textfield delegate methods
extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print(textField.attributedText)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print(textField.attributedText)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
