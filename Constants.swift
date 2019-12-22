//
//  Constants.swift
//  Snap-App
//
//  Created by Tushar Gusain on 10/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import Foundation
import Firebase

struct Constants {
    struct Refs {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("Chats")
        static let databaseUsers = databaseRoot.child("Users")
        static let databaseStorage = Storage.storage()
        static let databaseImages = databaseStorage.reference().child("images")
    }
}
