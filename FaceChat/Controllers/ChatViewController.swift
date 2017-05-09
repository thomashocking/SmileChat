//
//  ChatViewController.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import Firebase
import GrowingTextView
import FirebaseDatabaseUI

class ChatViewController: UIViewController, GrowingTextViewDelegate{

    @IBOutlet weak var emojiLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var emojiLabel: UILabel!
    private var visage : Visage?
    private let notificationCenter : NotificationCenter = NotificationCenter.default
    @IBOutlet weak var messageTable: UITableView!
    
    @IBOutlet weak var heightOfChatBox: NSLayoutConstraint!
    @IBOutlet weak var bottomOfChatBox: NSLayoutConstraint!
    @IBOutlet weak var topOfTypingIndicator: NSLayoutConstraint!
    @IBOutlet weak var typingIndicator: UILabel!
    @IBOutlet weak var chatBox: GrowingTextView!
    var heightConst = 0.0
    var chatId:String = ""
    var showingType = ""
    var chatReference:FIRDatabaseReference?
    var chatDataSource:FUITableViewDataSource?
    private var userIsTypingRef: FIRDatabaseReference?
    private var usersShowingRef: FIRDatabaseReference?
    
    private var localShowing = false
    var isShowing:Bool{
        get {
            return localShowing
        }
        set {
            localShowing = newValue
            usersShowingRef?.updateChildValues([SmileUser.currentUser.id!:[showingType:localShowing]])
        }
    }
    
    private var localTyping = false
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef?.updateChildValues([SmileUser.currentUser.id!:localTyping])
        }
    }
    
    func scrollToBottom(animated:Bool){
        
        let count = self.chatDataSource?.tableView(self.messageTable, numberOfRowsInSection: 0)
        let indexPath = IndexPath(row: count! - 1, section: 0)
        //snippet
        //
        
        if count! > 0{
            
            self.messageTable.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    @IBOutlet weak var sendBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageTable.register(UINib(nibName: "TextMessageCell", bundle: nil), forCellReuseIdentifier: "Text")
        print("ay")
        self.observeTyping()
        self.chatBox.placeHolder = "Say something..."
        self.chatBox.placeHolderColor = UIColor(white: 0.8, alpha: 1.0)
        self.chatBox.maxHeight = 70.0
        self.chatBox.delegate = self
        self.heightConst = Double(self.bottomOfChatBox.constant)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardVisible(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.userIsTypingRef  = SmileBase.groupBaseSingleton.child(self.chatId).child("typingIndicator")
        self.usersShowingRef  = SmileBase.groupBaseSingleton.child(self.chatId).child("showing")

        self.heightConst = Double(self.bottomOfChatBox.constant)
        self.chatBox.layer.cornerRadius = 4
        self.chatBox.clipsToBounds = true
        self.chatReference = SmileBase.groupBaseSingleton.child(chatId+"/messages")
        let query = self.chatReference?.queryLimited(toLast: 25)
        self.chatDataSource = FUITableViewDataSource(query: query!,
                                                          view: self.messageTable,
                                                          populateCell: { (view, indexPath, snap) -> UITableViewCell in
                                                            
                                                            
                                                            let messageType = (snap.value as! [String:Any])["messageType"]! as! String
                                                            let cell = view.dequeueReusableCell(withIdentifier: self.getReuseId(messageType: messageType), for: indexPath) as! MessageTableViewCell
                                                            let message = SmileMessage.InitMessage(snapshot: snap, chatId: self.chatId, messageType: messageType)
                                                            cell.setup(message: message)
                                                            
                                                            return cell
        })
        
        
        
        self.messageTable.dataSource = self.chatDataSource
        self.messageTable.rowHeight = UITableViewAutomaticDimension
        self.messageTable.estimatedRowHeight = 150.0
        query!.observe(.childAdded, with: { [unowned self] _ in
            self.scrollToBottom(animated: true)
        })
        
        self.usersShowingRef?.observe(.value, with: { (faceData:FIRDataSnapshot) in
            let dict = faceData.value as! [String:Any]
            for key in dict.keys{
                if key != SmileUser.currentUser.id{
                    let values = dict[key] as! [String:Bool]
                    for showingKey in values {
                        if showingKey.value == true{
                            if (showingKey.key == "smileAndWinking") {
                                self.emojiLabel.text = "😜"
                            } else if (showingKey.key == "winking") {
                                self.emojiLabel.text = "😉"
                            } else if (showingKey.key == "smile") {
                                self.emojiLabel.text = "😃"
                            } else {
                                self.emojiLabel.text = "😐"
                            }
                            if self.emojiLabelHeight.constant == 0{
                                UIView.animate(withDuration: 0.3, animations: {
                                    self.emojiLabelHeight.constant = 53
                               
                                    self.view.setNeedsLayout()
                                })
                            }
                        }else{
                            self.emojiLabelHeight.constant = 0
                            self.view.setNeedsLayout()
                        }
                        break
                    }
                }
            }
            
        })
        
        // Do any additional setup after loading the view.
        visage = Visage(cameraPosition: Visage.CameraDevice.faceTimeCamera, optimizeFor: Visage.DetectorAccuracy.higherPerformance)
        
        //If you enable "onlyFireNotificationOnStatusChange" you won't get a continuous "stream" of notifications, but only one notification once the status changes.
        visage!.onlyFireNotificatonOnStatusChange = false
        
        
        //You need to call "beginFaceDetection" to start the detection, but also if you want to use the cameraView.
        visage!.beginFaceDetection()
        
        //This is a very simple cameraView you can use to preview the image that is seen by the camera.
        let cameraView = visage!.visageCameraView
        cameraView.isHidden = true
        self.view.addSubview(cameraView)
        
        emojiLabel.text = "😐"
        emojiLabel.font = UIFont.systemFont(ofSize: 50)
        emojiLabel.textAlignment = .center
        
        //Subscribing to the "visageFaceDetectedNotification" (for a list of all available notifications check out the "ReadMe" or switch to "Visage.swift") and reacting to it with a completionHandler. You can also use the other .addObserver-Methods to react to notifications.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "visageFaceDetectedNotification"), object: nil, queue: OperationQueue.main, using: { notification in
            
            if ((self.visage!.hasSmile == true && self.visage!.isWinking == false)) {
                self.showingType = "smile"
                self.isShowing = true
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "You: 😃", style: .plain, target: nil, action: nil)
            } else {
                self.showingType = "neutral"
                self.isShowing = true
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "You: 😐", style: .plain, target: nil, action: nil)
            }
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.showingType = "neutral"
        self.isShowing = true
        self.visage?.beginFaceDetection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.showingType = "none"
        self.isShowing = false
        self.visage?.endFaceDetection()
    }
    
    func textViewDidChangeHeight(_ height: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            print(height)
            self.heightOfChatBox.constant = height
            self.view.layoutIfNeeded()
            self.chatBox.layoutIfNeeded()
        }
        
        let when = DispatchTime.now() + 0.1 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.scrollToBottom(animated: false)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !textView.text.isEmpty{
            self.isTyping = true
           
        }else{
            self.isTyping = false
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReuseId(messageType:String) -> String{
        if messageType == "text"{
            return "Text"
        }
        return ""
    }
    
    
    
    @IBAction func sendMessage(_ sender: Any) {
        let newMessageRef = SmileBase.groupBaseSingleton.child(self.chatId+"/messages").childByAutoId()
        let message = [
            "senderId":FIRAuth.auth()!.currentUser!.uid,
            "senderName":SmileUser.currentUser.name!,
            "senderPhotoURL":SmileUser.currentUser.profilePicURL!,
            "heartReactions":"0",
            "text":self.chatBox.text,
            "date":"\(Date().description)",
            "messageType":"text"
            ] as [String:Any]
        
        SmileBase.groupBaseSingleton.child(self.chatId+"/friends").observeSingleEvent(of: .value, with: { (friendData) in
            let friends = friendData.value as! Array<String>
    
            for friend in friends{
                let newNotificationRef = SmileBase.groupBaseSingleton.child(self.chatId+"/notifications/\(friend)")
                
                newNotificationRef.updateChildValues(["\(message["messageType"]!)":true])
            }
        })
        
        self.chatBox.text = ""
        self.isTyping = false
        
        newMessageRef.setValue(message)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
