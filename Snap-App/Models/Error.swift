//
//  Error.swift
//  Snap-App
//
//  Created by Tushar Gusain on 20/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import Foundation

enum AddFriendError: Error {
    case NotFoundError
    case AddingMyselfError
    case AlreadyAddedError
}
