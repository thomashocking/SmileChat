//
//  NewChatViewController.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/28/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKCoreKit
import Firebase



class NewChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    let connection: FBSDKGraphRequestConnection = FBSDKGraphRequestConnection()
    var friendData: [(String, String, UIImage)]?
    var friendsToAdd: [String]?

    @IBOutlet weak var friendTable: UITableView!
    @IBOutlet weak var friendLoader: UIActivityIndicatorView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadFriends()
        self.friendTable.register(UINib(nibName: "FriendTableViewCell", bundle: nil), forCellReuseIdentifier: "Friend")
        self.friendTable.dataSource = self
        self.friendTable.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadFriends(){
        self.friendData = [(String, String, UIImage)]()
        self.connection.add(FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "friends" as AnyObject])) { (connection, result, e) in
            if (e == nil){
                let listOfFriends = self.processFriends(result: result)
                let friendConnection = FBSDKGraphRequestConnection()
                let numberOfFriends = listOfFriends.count
                for (name, friendId) in listOfFriends{
                    friendConnection.add(FBSDKGraphRequest(graphPath:friendId, parameters: ["fields": "picture.type(large)" as AnyObject]) , completionHandler: { (connection, result, e) in
                        
                        if (e == nil){
                            let photoURL = self.processFriendPhotoURL(result: result)
                            self.getDataFromUrl(url: photoURL) { (data, response, error)  in
                                guard let data = data , error == nil else { return }
                                DispatchQueue.main.async() { () -> Void in
                                    print("Download Finished")
                                    let image = UIImage(data: data)
                                    self.friendData?.append((name, friendId, image!))
                                    if self.friendData?.count == numberOfFriends{
                                        self.friendTable.reloadData()
                                        self.friendLoader.stopAnimating()
                                    }
                                }
                            }
                        }
                    })
                }
                if numberOfFriends > 0 {
                    friendConnection.start()
                }
            }else{
                print(e ?? "dungoofed")
            }
        }
        self.connection.start()
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    func getDataFromUrl(url: URL, completion: @escaping ((_ picData: Data?, _ response: URLResponse?, _ e: Error? ) -> Void)) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func processFriends(result:Any?) -> [(String, String)]{
        
        
        var friendList = [(String, String)]()
        let friendDict = (result as! Dictionary<String, AnyObject>)["friends"]
        let friendData = friendDict?["data"] as! [[String : AnyObject]]
        for friend in friendData{
            friendList.append((friend["name"] as! String, friend["id"] as! String))
        }
        return friendList
    }
    
    func processFriendPhotoURL(result:Any?) -> URL{
        let friendPhotoDict = (result as! Dictionary<String, AnyObject>)["picture"]
        let friendData = friendPhotoDict?["data"] as! [String : AnyObject]
        let friendPictureURL = friendData["url"] as! String
        return URL(string: friendPictureURL)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Friend") as! FriendTableViewCell
        cell.friendImage.image = self.friendData?[(indexPath as NSIndexPath).row].2
        cell.friendName.text = self.friendData?[(indexPath as NSIndexPath).row].0
        cell.friendId = self.friendData?[(indexPath as NSIndexPath).row].1
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.friendData != nil{
            return self.friendData!.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friendDataPiece = self.friendData![indexPath.row]
        let friendId = friendDataPiece.1
        var friendParseIDs = [String]()
        var count = 0
        let newEventRef = SmileBase.groupBaseSingleton.child(friendId)

        SmileBase.fbConvertBaseSingleton.child(friendId).observeSingleEvent(of: .childAdded, with: { (snapshot) in
            SmileBase.userBaseSingleton.child(snapshot.key).child("chats").updateChildValues([newEventRef.key : snapshot.key])
            count += 1;
            friendParseIDs.append(snapshot.key)
            
            if count == 1{
                SmileBase.userBaseSingleton.child(FIRAuth.auth()!.currentUser!.uid).child("chats").updateChildValues([newEventRef.key : true])
                friendParseIDs.append(FIRAuth.auth()!.currentUser!.uid)
                let group = [
                    "title":"New Chat",
                    "friends":friendParseIDs,
                    "friendNames":[friendDataPiece.0, SmileUser.currentUser.name!],
                    "profilePhotos":[],
                    "notifications":[]
                    ] as [String : Any]
                self.dismiss(animated: true, completion: nil)
                newEventRef.setValue(group)

            }
            
        })
        
    }

}
