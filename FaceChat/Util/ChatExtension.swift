//
//  ChatExtension.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension ChatViewController{
    func keyboardVisible(_ notification: Notification) {
        print("keyboardVisible")
        let userInfo:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomOfChatBox.constant = keyboardHeight+8
            self.view.layoutIfNeeded()
        })
        
        self.scrollToBottomWithDelay()
    }
    
    func keyboardHidden(_ notification: Notification) {
        let userInfo:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        _ = keyboardRectangle.height
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomOfChatBox.constant = CGFloat(self.heightConst)
            self.view.layoutIfNeeded()
        })
        
        self.scrollToBottomWithDelay()
        
    }
    
    func observeTyping() {
        let typingIndicatorRef = SmileBase.groupBaseSingleton.child(self.chatId).child("typingIndicator")
        
        typingIndicatorRef.observe(.value) { (data: FIRDataSnapshot) in
            if data.exists(){
                var isTyping = false
                for(key,value) in data.value as! Dictionary<String, Any>{
                    if (value as! Bool) == true && key != SmileUser.currentUser.id!{
                        SmileBase.userBaseSingleton.child(key).observeSingleEvent(of: .value, with: { (data) in
                            let userData = data.value as! [String:Any]
                            self.typingIndicator.text = userData["name"] as! String + " is typing..."
                            UIView.animate(withDuration: 0.3, animations: {
                                self.topOfTypingIndicator.constant = 1
                                self.typingIndicator.alpha = 1
                            })
                            self.scrollToBottomWithDelay()
                            
                        }, withCancel: nil)
                        isTyping = true
                        break
                        
                    }
                }
                
                if isTyping == false{
                    UIView.animate(withDuration: 0.3, animations: {
                        self.topOfTypingIndicator.constant = -9
                        self.typingIndicator.alpha = 0
                    })
                    self.scrollToBottomWithDelay()
                }
            }
        }
    }
    
    func scrollToBottomWithDelay(){
        let when = DispatchTime.now() + 0.1 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.scrollToBottom(animated: false)
        }
    }
}
