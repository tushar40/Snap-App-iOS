//
//  ChatTableViewController.swift
//  Snap-App
//
//  Created by Tushar Gusain on 12/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import UIKit

class ChatTableViewController: UIViewController {
    
    //MARK:- Outlets
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    //MARK:- Member Variables
    private var friendList = [User]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var user: User! {
        didSet {
            title = "\(user.username)"
        }
    }
    private let segueIdentifier = "Open Chat"
    
    //MARK:- IBAction Methods
      @IBAction func addFriend(_ sender: UIBarButtonItem) {
        let defaults = UserDefaults.standard
        let alert = UIAlertController(title: user.name, message: "Specify your friend's username to add", preferredStyle: .alert)
        
        alert.addTextField { textField in
            if let name = defaults.string(forKey: "sa_name") {
                textField.text = name
            } else {
                let names = ["Ford", "Arthur", "Zaphod", "Trillian", "Slartibartfast", "Humma Kavula", "Deep Thought"]
                textField.text = names[Int(arc4random_uniform(UInt32(names.count)))]
            }
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] alertAction in
            if let textField = alert.textFields?[0], !textField.text!.isEmpty {
                FirebaseApi.shared.addFriendToDB(usernameFriend: textField.text!){ result in
                    switch result {
                    case .success(let friend):
                        self?.alert(title: "Successfully Added", message: "Added \(friend.username) as friend")
                        self?.getFriendList()
                    case .failure(let error):
                        switch error {
                        case .AddingMyselfError :
                            self?.alert(title: "Problem Adding", message: "You cannot add yourself as a friend")
                        case .NotFoundError :
                            self?.alert(title: "Problem Adding", message: "username: \(textField.text!) couldn't be found")
                        case .AlreadyAddedError:
                            self?.alert(title: "Already a friend", message: "username: \(textField.text!) is Already added")
                        }
                    }
                  
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
      }
    
    @IBAction func signOut(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to Sign Out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
               guard let self  = self else { return }
               FirebaseApi.shared.signOut { error in
                   if let error = error {
                       self.alert(title: "Problem signing out", message: error.localizedDescription)
                   } else {
                       if let storyboard = self.storyboard {
                        let vc = storyboard.instantiateViewController(withIdentifier: "LoginNavigationController") as! UINavigationController
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: false, completion: nil)
                       }
                   }
               }
           }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK:- Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCell()
        getFriendList()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        openedChat = false
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            if let chatVC = segue.destination as? ChatViewController {
                chatVC.user = user
                if let cell = sender as? ChatsTableViewCell {
                    chatVC.recipent = cell.user
                }
            }
        }
    }
    
    //MARK:- Custom Methods
    private func registerTableViewCell() {
        let tableViewCell = UINib(nibName: "ChatsTableViewCell", bundle: nil)
        self.tableView.register(tableViewCell, forCellReuseIdentifier: "ChatsTableViewCell")
        print(tableViewCell,tableView.visibleCells)
    }
    
    private func getFriendList() {
        self.friendList = [User]()
        FirebaseApi.shared.getFriendListFromDB(user: user) { [weak self] friend in
            guard let self = self else{
                return
            }
            if let index = self.friendIdPresent(id: friend.id) {
                self.friendList[index] = friend
            } else {
                self.friendList.append(friend)
            }
            print("updated friendList:", self.friendList)
        }
    }
    
    private func friendIdPresent(id: String) -> Int? {
        for (index,friend) in friendList.enumerated() {
            if friend.id == id {
                return index
            }
        }
        return nil
    }
}

//MARK:- UITableViewDelegate Methods
extension ChatTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueIdentifier, sender: tableView.cellForRow(at: indexPath))
    }
}

//MARK:- UITableViewDataSource Methods
extension ChatTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChatsTableViewCell") as? ChatsTableViewCell {
            cell.user = friendList[indexPath.item]
            return cell
        }
        return ChatsTableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
}
