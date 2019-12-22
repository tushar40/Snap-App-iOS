//
//  FirebaseApi.swift
//  Snap-App
//
//  Created by Tushar Gusain on 12/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import Firebase

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

var openedChat = false

class FirebaseApi {
    //MARK:- Member Variables
    static let shared = FirebaseApi()
    private var user = User(id: "", name: "", username: "", email: "", friends: [String]())
    private var handle: AuthStateDidChangeListenerHandle?
    private var message_dictionary = [String: JSQMessage]()
    
    //MARK:- Contructors
    init() { }
    
    //MARK:- Public Methods
    func getMessagesFromDB(forFriend: User, completion: @escaping (JSQMessage, String?) -> Void) {
        let childNodeName = getChildNameForChats(forFriend: forFriend)
        let query = Constants.Refs.databaseChats.child(childNodeName).queryLimited(toLast: 10)
        _ = query.observe(.childAdded, with: { (snapshot) in
            if let data = snapshot.value as? [String: Any],
                let id = data["sender_id"] as? String,
                let name = data["sender_username"] as? String,
                let msg_id = data["message_id"] as? String,
                let dateString = data["date"] as? String,
                let isMediaMessage = data["isMedia"] as? Bool {
                var text: String? = nil
                var url: String? = nil
                if let messageText = data["text"] as? String,
                    !messageText.isEmpty {
                    text = messageText
                }
                if let mediaUrl = data["mediaUrl"] as? String {
                    url = mediaUrl
                }
                if let messagePresent = self.message_dictionary[msg_id] {
                    print("Message already in array: ",messagePresent)
                }
                let date = dateFormatter.date(from: dateString)
                if isMediaMessage {
                    let jsqP = JSQPhotoMediaItem()
                    if id != self.user.id  {
                        jsqP.appliesMediaViewMaskAsOutgoing = false
                    }
                    if let sentMessage = JSQMessage(senderId: id, senderDisplayName: name, date: date, media: jsqP) {
                        self.message_dictionary[msg_id] = sentMessage
                        completion(sentMessage,url)
                    }
                } else {
                    if let sentMessage = JSQMessage(senderId: id, senderDisplayName: name, date: date, text: text) {
                        completion(sentMessage,nil)
                    }
                }
            }
        })
    }
    
    func getDeletedMessageFromDB(forFriend: User, completion: @escaping (JSQMessage) -> Void) {
        let childNodeName = getChildNameForChats(forFriend: forFriend)
        let query = Constants.Refs.databaseChats.child(childNodeName).queryLimited(toLast: 10)
        _ = query.observe(.childRemoved, with: { (snapshot) in
            if let data = snapshot.value as? [String: Any],
                let msg_id = data["message_id"] as? String {
                if let message = self.message_dictionary[msg_id] {
                    self.message_dictionary.removeValue(forKey: msg_id)
                    completion(message)
                } else {
                    print("Message not in array")
                    return
                }
            }
        })
    }
    
    func deleteMessageFromDB(recipent: User, message: JSQMessage, completion: @escaping () -> Void) {
        guard let message_id = getMessageIdFromDictionary(message: message) else { return }
        let childNodeName = getChildNameForChats(forFriend: recipent)
        let ref = Constants.Refs.databaseChats.child(childNodeName).child(message_id)
        completion()
        _ = ref.observe(.childAdded, with: { (snapshot) in
            if let dataUrl = snapshot.value as? String {
                if snapshot.key == "mediaUrl" {
                    self.deleteImage(mediaUrl: dataUrl, completion: {
                        print("deleted image from firebase storage.")
                    } )
                }
            }
        })
        ref.setValue(nil)
    }
    
    func storeMessageInDB(text: String?, date: Date, isMediaMessage: Bool, mediaData: Data?, recipent: User, completion: @escaping () -> Void) {

        uploadImage(data: mediaData, date: date) { [weak self] (url) in
            guard let self = self else {
                return
            }
            if isMediaMessage && url == nil {
                return
            }
            let childNodeName = self.getChildNameForChats(forFriend: recipent)
            let ref = Constants.Refs.databaseChats.child(childNodeName).childByAutoId()
            let user = self.user
            var urlString: String? = nil
            if let url = url {
                urlString = url.absoluteString
            }
            let dateString = dateFormatter.string(from: date)
            let message: [String : Any] = ["sender_id": user.id, "sender_username": user.username, "text": text, "recipent_id": recipent.id, "recipent_username": recipent.username, "message_id": ref.key!, "date": dateString, "isMedia": isMediaMessage, "mediaUrl": urlString]
            ref.setValue(message)
            completion()
        }
    }
    
    func addFriendToDB(usernameFriend: String, completion: @escaping (ResultAddFriend<User, AddFriendError>) -> Void) {
        let query = Constants.Refs.databaseUsers.queryOrdered(byChild: "username").queryEqual(toValue: usernameFriend)
        
        _ = query.observe(.value, with: { (snapshot) in
            if let childSnapshot = snapshot.children.nextObject() as? DataSnapshot,
                let data = childSnapshot.value as? [String: Any],
                let id = data["user_id"] as? String,
                let username = data["username"] as? String,
                let email = data["email"] as? String,
                let name = data["name"] as? String {
                print("snapshot:",childSnapshot)
                if self.isAlreadyAFriend(id: id) {
                    print("Already added as a friend")
                    completion(.failure(.AlreadyAddedError))
                } else if id == self.user.id {
                    print("can't add oneself as a friend")
                    completion(.failure(.AddingMyselfError))
                } else {
                    var friend = User(id: id, name: name, username: username, email: email, friends: [String]())
                    self.getFriendListIdFromDB(user: self.user) { friendId in
                        if let friendId = friendId  {
                            friend.friends.append(friendId)
                        }
                        print("adding friend: ",friend)
                        completion(.success(self.addFriendToFriendList(friend: friend)))
                    }
                }
            } else {
                completion(.failure(.NotFoundError))
            }
        })
        
    }
    
    func getFriendListFromDB(user: User, completion: @escaping (User) -> Void) {
        let query = Constants.Refs.databaseUsers.child(user.id).child("Friends")
        _ = query.observe(.childAdded, with: { (snapshot) in
            if let data = snapshot.value as? [String: String],
                let id = data["id"] {
                self.getUserDetailsFromDB(userId: id) { friend in
                    completion(friend)
                }
            }
        })
    }
    
    func getUserDetailsFromDB(userId: String, completion: @escaping (User) -> Void) {
        let query = Constants.Refs.databaseUsers
        
        _ = query.observe(.childAdded, with: { (snapshot) in
            if let data = snapshot.value as? [String: Any],
                let id = data["user_id"] as? String,
                let name = data["name"] as? String,
                let username = data["username"] as? String,
                let email = data["email"] as? String, id == userId {
                var user = User(id: id, name: name, username: username, email: email, friends: [String]())
                self.getFriendListIdFromDB(user: user) { friendId in
                    if let friendId = friendId {
                        user.friends.append(friendId)
                        print("friend id list:",user.friends)
                    } else {
                        print("user has no friends")
                    }
                    completion(user)
                }
                if user.id == self.user.id {
                    self.user = user
                }
            }
        })
    }
    
    func createUserInDB(user: User, completion: @escaping () -> Void) {
        print("user in createUserInDB: ",user)
        let ref = Constants.Refs.databaseUsers.child(user.id)
        
        let userDict: [String: Any] = ["user_id": user.id, "username": user.username, "name": user.name, "email": user.email]
        
        ref.setValue(userDict)
        self.user = user
        completion()
    }
    
    func registerUser(email: String, password: String, isLogin: Bool, completion: @escaping (AuthDataResult?, Error?,User) -> Void) {
        if isLogin {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let userDetails = authResult?.user {
                    self.getUserDetailsFromDB(userId: userDetails.uid) { user in
                        self.user = user
                        completion(authResult, error, self.user)
                    }
                } else {
                    completion(authResult, error, self.user)
                }
            }
        } else {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                completion(authResult, error, self.user)
            }
        }
    }
    
    func initializeLoginStateChangeHandle(completion: @escaping (User) -> Void) {
        handle = Auth.auth().addStateDidChangeListener { (auth, userDetails) in
          if let userDetails = userDetails {
            // The user's ID, unique to the Firebase project.
            // Do NOT use this value to authenticate with your backend server,
            // if you have one. Use getTokenWithCompletion:completion: instead.
            // let photoURL = user.photoURL
            
            if let email = userDetails.email,
                !userDetails.uid.isEmpty {
                self.user.email = email
                self.user.id = userDetails.uid
                FirebaseApi.shared.getUserDetailsFromDB(userId: self.user.id) { user in
                    self.user = user
                    completion(user)
                }
            }
          }
        }
    }
    
    func removeLoginStateChangeHandle() {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            user = User(id: "", name: "", username: "", email: "", friends: [String]())
            completion(nil)
        } catch {
            print("Error Signing out",error.localizedDescription)
            completion(error)
        }
    }
    
    func getImage(mediaUrl: String, completion: @escaping (Data?) -> Void) {
        let storageRef = Constants.Refs.databaseStorage.reference(forURL: mediaUrl)
        storageRef.downloadURL(completion: { (url, error) in
            if let error = error {
                print("Error getting url: ",error.localizedDescription)
                completion(nil)
            }
            do {
                let data =  try Data(contentsOf: url!)
                completion(data)
            } catch {
                print("Error downloading image")
                completion(nil)
            }
        })
    }
    
    //MARK:- Private Methods
    private func getChildNameForChats(forFriend: User) -> String {
        var childNodeName = "\(user.id)-\(forFriend.id)"
        if user.id > forFriend.id {
            childNodeName = "\(forFriend.id)-\(user.id)"
        }
        return childNodeName
    }
    
    private func addFriendToFriendList(friend: User) -> User {
        if !isAlreadyAFriend(id: friend.id) {
            user.friends.append(friend.id)
        } else {
            user.friends[user.friends.count - 1] = friend.id
        }
        let refU = Constants.Refs.databaseUsers.child(user.id).child("Friends").child(friend.id)
        print("add friend to db reference:",refU)
        let friendUserValue = ["id": friend.id]
        refU.setValue(friendUserValue)
        let refF = Constants.Refs.databaseUsers.child(friend.id).child("Friends").child(user.id)
        let userFriendValue = ["id": user.id]
        refF.setValue(userFriendValue)
        return friend
    }
    
    private func getFriendListIdFromDB(user: User, completion: @escaping (String?) -> Void) {
        let query = Constants.Refs.databaseUsers.child(user.id).child("Friends")
        var queryExist = false
        _ = query.observe(.childAdded, with: { (snapshot) in
            queryExist = true
            if let data = snapshot.value as? [String: String],
                let id = data["id"] {
                completion(id)
            }
        })
        if !queryExist {
            completion(nil)
            return
        }
    }
    
    private func isAlreadyAFriend(id: String) -> Bool {
        for friendId in user.friends {
            if id == friendId {
                return true
            }
        }
        return false
    }
    
    private func uploadImage(data: Data?, date: Date, completion: @escaping (URL?) -> Void) {
        let timestamp = Int(date.timeIntervalSince1970)
        let ref = Constants.Refs.databaseImages.child("img-\(data.hashValue)-\(timestamp).jpg")
        
        guard let data = data else {
            completion(nil)
            return
        }
        
        let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: ",error.localizedDescription)
                completion(nil)
                return
            }
            
            ref.downloadURL(completion: { (url, error) in
                if let error = error { print("Error getting firebase image url: ",error.localizedDescription) }
                completion(url)
            })
        }
        uploadTask.resume()
    }
    
    private func deleteImage(mediaUrl: String, completion: @escaping () -> Void) {
        let storageRef = Constants.Refs.databaseStorage.reference(forURL: mediaUrl)
        storageRef.delete { error in
            if let error = error {
                print("Error deleting image from firebase: ",error.localizedDescription)
                return
            }
            completion()
        }
    }
    
    private func getMessageIdFromDictionary(message: JSQMessage) -> String?{
        for (key,value) in message_dictionary {
            if value == message {
                return key
            }
        }
        return nil
    }
}
