//
//  ViewController.swift
//  Snap-App
//
//  Created by Tushar Gusain on 10/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {

    //MARK:- Variables
    private var messages = [JSQMessage]()
    
    private var imagePickerVC: UIImagePickerController {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.allowsEditing = true
        vc.sourceType = .camera
        return vc
    }
    
    private var albumPickerVC: UIImagePickerController {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.allowsEditing = true
        vc.sourceType = .photoLibrary
        return vc
    }
    
    var user: User!
    
    var recipent: User! 
    
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    
    //MARK:- IBAction Methods
    @IBAction func sendImage(_ sender: UIBarButtonItem) {
        present(imagePickerVC, animated: true)
    }
    
    //MARK:- Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
//        let defaults = UserDefaults.standard
        
//        if let id = defaults.string(forKey: "sa_id"),
//            let name = defaults.string(forKey: "sa_name") {
//            senderId = id
//            senderDisplayName = name
//            FirebaseApi.shared.user = User(id: id, name: senderDisplayName, username: senderDisplayName, email: "", friends: [String]())
//        } else {
//            senderId = String(arc4random_uniform(999999))
//            senderDisplayName = ""
//            FirebaseApi.shared.user = User(id: senderId, name: senderDisplayName, username: senderDisplayName, email: "", friends: [String]())
//
//            defaults.set(senderId, forKey: "sa_id")
//
//            defaults.synchronize()
//
//            showDisplayDialog()
//        }
        openedChat = true
        senderId = user.id
        senderDisplayName = user.username
        title = "Chat: \(recipent.username)"
        print("messages on loading the chat screen: ",messages)
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        FirebaseApi.shared.getMessagesFromDB(forFriend: recipent) { chatMessage,url in
            self.messages.append(chatMessage)
            print("got message from firebasedatabse",chatMessage,url)
            print("updated messages array:",self.messages)
            if let url = url {
                FirebaseApi.shared.getImage(mediaUrl: url) { [weak self] data in
                    guard let self = self else { return }
                    guard let data = data else { return }
                    let image = UIImage(data: data)
                    (chatMessage.media as! JSQPhotoMediaItem).image = image
                    self.finishSendingMessage()
                }
            }
            self.finishReceivingMessage()
            print("messages",self.messages)
        }
        FirebaseApi.shared.getDeletedMessageFromDB(forFriend: recipent) { [weak self] message in
            guard let self = self else { return }
            let index = self.messages.firstIndex(of: message)!
            self.messages.remove(at: index)
            self.finishSendingMessage()
            self.finishReceivingMessage()
            print("updated message array after deleting:", self.messages)
        }
        inputToolbar.contentView.leftContentPadding = 14
        inputToolbar.contentView.rightContentPadding = 14
    }
    
    override func viewWillAppear(_ animated: Bool) {
        openedChat = true
    }

    //MARK:- JSQCollectionView methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!
    {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName!)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let dateString = timeFormatter.string(from: messages[indexPath.item].date)
        return NSAttributedString(string:dateString)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 20
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return messages[indexPath.item].senderId == senderId ? 0 : 15
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        FirebaseApi.shared.storeMessageInDB(text: text, date: date, isMediaMessage: false, mediaData: nil, recipent: recipent) { [weak self] in
            self?.finishSendingMessage()
            JSQSystemSoundPlayer.jsq_playMessageSentAlert()
        }
    }
    override func didPressAccessoryButton(_ sender: UIButton!) {
        present(albumPickerVC, animated: true)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        showImage(message: messages[indexPath.item])
    }
    //MARK:- Custom methods
    private func deleteMessage(message: JSQMessage) {
        FirebaseApi.shared.deleteMessageFromDB(recipent: recipent, message: message) { [weak self] in
            guard let self = self else { return }
            self.finishReceivingMessage()
            self.finishSendingMessage()
        }
    }
    
    private func showImage(message: JSQMessage) {
        let storyBoard = UIStoryboard(name: "Main", bundle:nil)
        if let showImageVC = storyBoard.instantiateViewController(withIdentifier: "ShowMessageImageViewController") as? ShowMessageImageViewController {
            showImageVC.modalPresentationStyle = .fullScreen
            showImageVC.message = message
            showImageVC.deleteMessage = deleteMessage
            showImageVC.isIncomingMessage = senderId != message.senderId
            self.present(showImageVC, animated: false, completion: nil)
        }
    }
}

//MARK:- ImagePicker delegate methods
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("no image found")
            return
        }
        FirebaseApi.shared.storeMessageInDB(text: nil, date: Date(), isMediaMessage: true, mediaData: image.pngData(), recipent: recipent) { [weak self] in
            self?.finishSendingMessage()
            JSQSystemSoundPlayer.jsq_playMessageSentAlert()
        }
    }
}
