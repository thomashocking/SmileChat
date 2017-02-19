//
//  MessageTableViewCell.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import FirebaseStorage

class MessageTableViewCell: UITableViewCell {

    var message:SmileMessage?
    var photoUrl:String = ""
    
    
    //not used currently.
    func setSeen(seenCount:String, shouldShow:Bool){}
    func getSeen() -> UILabel? {return nil}
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setup(message:SmileMessage){
        self.message = message
    }
    
    func isToday(date: Date) -> Bool {
        return NSCalendar.current.isDateInToday(date)
    }
    
    func isNow(date:Date) -> Bool{
        let oldDate = Date(timeIntervalSinceNow: -100)
        if date > oldDate {return true}
        return false
    }
    
    func fetchProfilePhoto(photoUrl:String, profileView:UIImageView){
        FIRStorage.storage().reference(forURL: photoUrl).data(withMaxSize: (1*512*512), completion: { (imageData,error) in
            profileView.image = UIImage(data: imageData!)
        })
    }
}
