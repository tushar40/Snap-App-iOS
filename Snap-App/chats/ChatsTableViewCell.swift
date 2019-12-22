//
//  ChatsTableViewCell.swift
//  Snap-App
//
//  Created by Tushar Gusain on 12/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import UIKit

class ChatsTableViewCell: UITableViewCell {

    //MARK:- Outlets
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    //MARK:- Member Variables
    var user: User!  {
        didSet {
            nameLabel.text = user.username
        }
    }
    //MARK:- UITableViewCell Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.text = "no name"
        // Initialization code
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
}
