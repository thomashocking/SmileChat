//
//  SmileMessage.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import Foundation
import Firebase

class SmileMessage{
    
    var contents: [String: Any]
    var messageId:String
    var groupId:String
    var date: Date
    var dateString:String
    var timeComp: String
    var dateComp: String
    var senderId:String
    
    //factory
    static func InitMessage(snapshot:FIRDataSnapshot, chatId:String, messageType:String) -> SmileMessage{
        if messageType == "text"{
            return TextMessage(snapshot: snapshot, chatId: chatId)!
        }
        return SmileMessage(snapshot: snapshot, chatId: chatId)!
    }
    
    init?(snapshot:FIRDataSnapshot, chatId:String) {
        self.messageId = snapshot.key
        self.groupId = chatId
        self.contents = snapshot.value as! [String:Any]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let dateString = contents["date"] as! String
        self.date = formatter.date(from: dateString)!
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.dateString = formatter.string(from: self.date)
        let comps:[String] = self.dateString.components(separatedBy: ",")
        if comps.count > 2 {
            self.timeComp = comps[2]
        }else if comps.count == 1{
            self.timeComp = comps[0]
        }else{
            self.timeComp = comps[1]
        }
        self.dateComp = comps[0]
        self.senderId = contents["senderId"] as! String
    }
}

class TextMessage: SmileMessage{}
