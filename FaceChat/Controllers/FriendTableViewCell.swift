//
//  FriendTableViewCell.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {

    
    @IBOutlet weak var friendImage: UIImageView!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var friendName: UILabel!
    var friendId:String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.friendImage.layer.cornerRadius = 16
        self.friendImage.layer.masksToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
