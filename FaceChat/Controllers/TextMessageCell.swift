//
//  TextMessageCell.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import Firebase

class TextMessageCell: MessageTableViewCell {
  
    @IBOutlet weak var senderImage: UIImageView!
    @IBOutlet weak var senderName: UILabel!
    @IBOutlet weak var messageBody: UILabel!
    
    var groupId:String?
    var messageId:String?
    
    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    var userReacted = false
    
    override func awakeFromNib() {
        
    }
  
    override
    func setup(message:SmileMessage){
        super.setup(message: message)
        self.messageBody.text = (message as! TextMessage).contents["text"] as? String
        let senderName = (message as! TextMessage).contents["senderName"] as? String
        self.senderName.text = senderName?.components(separatedBy: " ")[0]
        self.senderImage.contentMode =  .scaleAspectFit
        if self.senderImage.image == nil || self.photoUrl != message.contents["senderPhotoURL"] as! String{
            self.fetchProfilePhoto(photoUrl:  message.contents["senderPhotoURL"] as! String, profileView: self.senderImage)
            self.photoUrl = message.contents["senderPhotoURL"] as! String
        }
        
        self.selectionStyle = .none
  
        
        if self.isNow(date: message.date){
            self.dateLabel.text = "Now"
        }else if self.isToday(date: message.date){
            self.dateLabel.text = message.timeComp
        }else{
            self.dateLabel.text = message.dateComp + " " + message.timeComp
        }
        self.messageId = message.messageId
        self.groupId = message.groupId
    }
    
    
}
