//
//  SplashViewController.swift
//  Snap-App
//
//  Created by Tushar Gusain on 14/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    //MARK:- Member Variables
    var user: User!
    private var showedVC = false

    //MARK:- Lifecycle methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseApi.shared.initializeLoginStateChangeHandle() { [weak self] user in
            guard let self = self else {
                return
            }
            FirebaseApi.shared.removeLoginStateChangeHandle()
            self.user = user
            let storyBoard = UIStoryboard(name: "Main", bundle:nil)
            print("user on state changed",user)
            if !self.showedVC {
                if user.id == "" {
                    let loginNavVC = storyBoard.instantiateViewController(withIdentifier: "LoginNavigationController") as! UINavigationController
                    loginNavVC.modalPresentationStyle = .fullScreen
                    self.present(loginNavVC, animated: false, completion: { self.showedVC = true })
                } else {
                    let ChatNavVC = storyBoard.instantiateViewController(withIdentifier: "ChatNavigationController") as! UINavigationController
                    let chatVC = ChatNavVC.viewControllers.first as! ChatTableViewController
                    chatVC.user = user
                    ChatNavVC.modalPresentationStyle = .fullScreen
                    self.present(ChatNavVC, animated: false, completion: { self.showedVC = true })
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak self] in
            if let self = self, !self.showedVC {
                let storyBoard = UIStoryboard(name: "Main", bundle:nil)
                let loginNavVC = storyBoard.instantiateViewController(withIdentifier: "LoginNavigationController") as UIViewController
                loginNavVC.modalPresentationStyle = .fullScreen
                self.present(loginNavVC, animated: false, completion: nil)
                self.showedVC = true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
     }

}
