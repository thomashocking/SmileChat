//
//  ChatsViewController.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/29/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabaseUI
import FirebaseDatabase
import FirebaseStorage


class ChatsViewController: UIViewController, UITableViewDelegate{

    @IBOutlet weak var chatTable: UITableView!
    var groupTableDS:FUITableViewDataSource?
    var query:FIRDatabaseQuery?
    var selectedChat:String?
    let cache = NSCache<AnyObject, AnyObject>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.viewDidLoad()
        self.chatTable.delegate = self
        self.chatTable.register(UINib(nibName: "GroupTableCell", bundle: nil), forCellReuseIdentifier: "GroupCell")
        self.query = SmileBase.userBaseSingleton.child(FIRAuth.auth()!.currentUser!.uid).child("/chats").queryOrderedByKey()
        self.groupTableDS = EditableFUITableViewDataSource(query: self.query!, view: self.chatTable, populateCell: { (tableView, indexPath, data) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell") as! GroupTableCell
            SmileBase.groupBaseSingleton.child(data.key).observe(.value, with: { (snap) in
                if snap.exists(){
                    cell.initWithData(snap: snap)
                }
            })
            return cell
        })
        
        self.chatTable.dataSource = self.groupTableDS
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedChat = (self.chatTable.cellForRow(at: indexPath) as! GroupTableCell).chatId 
        
        let controller = cache.object(forKey: self.selectedChat! as AnyObject) as? ChatViewController ??
            (storyboard?.instantiateViewController(withIdentifier: "ChatViewController"))! as! ChatViewController
        cache.setObject(controller, forKey: self.selectedChat! as AnyObject)
        controller.chatId = self.selectedChat!
        navigationController!.pushViewController(controller, animated: true)    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
