//
//  GroupTableCell.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import Firebase

class GroupTableCell: UITableViewCell {

    @IBOutlet weak var friendImage: UIImageView!
    var groupData:Dictionary<String, Any>?
    @IBOutlet weak var lastMessageText: UILabel!
    @IBOutlet weak var friendName: UILabel!
    var chatId:String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func initWithData(snap:FIRDataSnapshot){
        self.groupData = (snap.value as! Dictionary<String, AnyObject>)
        let friendsList = self.groupData!["friendNames"] as! [String]
        let friendIds = self.groupData!["friends"] as! [String]
        SmileBase.userBaseSingleton.child(friendIds.filter({$0 != SmileUser.currentUser.id!})[0]).observeSingleEvent(of: .value, with: { (snap) in
            FIRStorage.storage().reference(forURL: (snap.value as! Dictionary<String, AnyObject>)["photoURL"] as! String).data(withMaxSize: (1*512*512), completion: { (imageData,error) in
                self.friendImage.image = UIImage(data: imageData!)
            
            })
        })
        self.friendImage.layer.cornerRadius = 20
        self.friendImage.clipsToBounds = true
        self.chatId = snap.key
        self.friendName.text = friendsList.filter({$0 != SmileUser.currentUser.name!})[0]
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
