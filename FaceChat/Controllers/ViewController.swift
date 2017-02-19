//
//  ViewController.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/27/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import Firebase
import CoreLocation
import FirebaseStorage

class ViewController: UIViewController{
    @IBOutlet weak var loginButton: UIButton!
    public func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("ay")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loginButton.addTarget(self, action: #selector(self.loginPressed), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let lm = LoginManager()
        lm.logOut()
        if AccessToken.current != nil {
            let nextViewController = self.storyboard!.instantiateViewController(withIdentifier: "GroupNav") as! UINavigationController
            self.present(nextViewController, animated:true, completion:nil)
        }
    }
    
    @objc func loginPressed() {
        let fbLoginManager = LoginManager()
        let when = DispatchTime.now() + 15.0
        DispatchQueue.main.asyncAfter(deadline: when) {
          //  self.fbLoginBtn.isHidden = false
           // self.activityIndicator.stopAnimating()
        }
        
        fbLoginManager.logIn([.publicProfile, .email, .userFriends], viewController: self) { (result) in
            switch result {
            case .failed(let error):
                print(error)
                
            case .cancelled:
                print("user cancelled!")
                
            case .success( _, _, _):
                self.getFBUserData()
                print("ayyy")
            }
            
        }
    }
    
    class MyProfileRequest: GraphRequestProtocol {
        
        
        struct Response: GraphResponseProtocol {
            
            init(rawResponse: Any?) {
                // Decode JSON from rawResponse into other properties here.
                let jsonData = rawResponse as! Dictionary<String, Any>
                print(jsonData)
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: AccessToken.current!.authenticationToken)
                FIRAuth.auth()!.signIn(with: credential)  { (user, error) in
                    let pictureData = (jsonData["picture"]! as! [String : Any])
                    let pictureUrl = (pictureData["data"] as! [String: Any]) ["url"] as! String
                    ViewController.MyProfileRequest.getDataFromUrl(url: URL(string: pictureUrl)!, completion: { (data, response, error) in
                        SmileBase.userProfilePicStorage.child(user!.uid).put(data!, metadata: nil) { metadata, error in
                            if error == nil{
                                // Metadata contains file metadata such as size, content-type, and download URL.
                                let downloadURL = metadata!.downloadURL
                                
                                let newUser = [
                                    "provider": "Facebook",
                                    "name": jsonData["name"]!,
                                    "fbid" : jsonData["id"]!,
                                    "photoURL" : "\(downloadURL()!)",
                                    "canUpdateLocations":"false",
                                    "lastLocation":"(0,0)",
                                    "lastUpdatedLocationTime":"-1",
                                    "batteryLevel":0
                                    ] as [String : Any]
                                
                                let userMap = [
                                    user!.uid:true
                                ]
                                
                                
                                SmileBase.userBaseSingleton.child(user!.uid).updateChildValues(newUser)
                                SmileBase.fbConvertBaseSingleton.child(jsonData["id"] as! String).updateChildValues(userMap)
                                SmileUser.currentUser.id = FIRAuth.auth()!.currentUser!.uid
                                SmileUser.currentUser.name = (jsonData["name"] as! String)
                                SmileUser.currentUser.lastLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
                                SmileUser.currentUser.isNew = true
                                SmileUser.currentUser.lastUpdatedLocationTime = Date()
                                SmileUser.currentUser.canUpdateLocations = false
                                SmileUser.currentUser.profilePicURL = "\(downloadURL()!)"
                                SmileUser.currentUser.profilePic = UIImage(data: data!)
                                SmileUser.currentUser.completion()
                            }
                        }
                    })
                    
                }
            }
            
        }
        
        static func getDataFromUrl(url: URL, completion: @escaping ((_ picData: Data?, _ response: URLResponse?, _ e: Error? ) -> Void)) {
            URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                completion(data, response, error)
                }.resume()
        }
        
        
        var graphPath = "/me"
        var parameters: [String : Any]? = ["fields": "id, name, picture.type(large)"]
        var accessToken = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
    }

    
    func getFBUserData(){
        
        let connection = GraphRequestConnection()
        let request = MyProfileRequest()
        SmileUser.currentUser.completion =  {self.performSegue(withIdentifier: "toMainScreen", sender: self)}
        connection.add(request) { response, result in
            switch result {
            case .success(_):
                print("ay")
            case .failed(let error):
                print(error)
            }
        }
        connection.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

