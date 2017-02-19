//
//  SmileUser.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/27/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseStorage
import FirebaseAuth

class SmileUser {
    static let currentUser = SmileUser()
    var name:String?
    var profilePic:UIImage?
    var profilePicURL:String?
    var id:String?
    var canUpdateLocations:Bool?
    var lastLocation:CLLocationCoordinate2D?
    var lastUpdatedLocationTime:Date?
    var signalUID:String?
    var completion: () -> Void?
    var isNew:Bool?
    
    private init(){
        name = nil
        profilePic = nil
        profilePicURL = nil
        id = nil
        canUpdateLocations = true
        lastLocation = nil
        lastUpdatedLocationTime = nil
        signalUID = nil
        isNew = nil
        completion = {return}
    }
    
    static func buildCurrentUser( completion: @escaping () -> Void){
        if let _ = FIRAuth.auth()?.currentUser {
            SmileUser.currentUser.id = FIRAuth.auth()!.currentUser!.uid
            SmileBase.userBaseSingleton.child(SmileUser.currentUser.id!).observeSingleEvent(of: .value, with: { (userData)  in
                if userData.exists(){
                    SmileUser.currentUser.name = ((userData.value! as! Dictionary<String, Any>)["name"] as! String)
                    if let coord = ((userData.value! as! Dictionary<String, Any>)["lastLocation"]){
                        let coords = coord as! String
                        var coordsArr = coords.components(separatedBy: ",")
                        coordsArr[0].remove(at: coordsArr[0].startIndex)
                        coordsArr[1].remove(at: coordsArr[1].index(before: coordsArr[1].endIndex))
                        let lat = CLLocationDegrees(coordsArr[0])
                        let long = CLLocationDegrees(coordsArr[1])
                        SmileUser.currentUser.lastLocation = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
                        
                        //self.syncOneSignal()
                        SmileUser.currentUser.isNew = false
                        let timeVal:String = ((userData.value! as! Dictionary<String, Any>)["lastUpdatedLocationTime"])! as! String
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat =  "yyyy-MM-dd HH:mm:ss Z"
                        SmileUser.currentUser.lastUpdatedLocationTime = dateFormatter.date(from: timeVal)
                    }
                    let boolVal = Bool.init(((userData.value! as! Dictionary<String, Any>)["canUpdateLocations"] as! String))
                    SmileUser.currentUser.canUpdateLocations = boolVal!
                    SmileBase.userBaseSingleton.child(FIRAuth.auth()!.currentUser!.uid).observeSingleEvent(of: .value, with: { (snap) in
                        SmileUser.currentUser.profilePicURL = (snap.value as! Dictionary<String, AnyObject>)["photoURL"] as? String
                        FIRStorage.storage().reference(forURL: (snap.value as! Dictionary<String, AnyObject>)["photoURL"] as! String).data(withMaxSize: (1*512*512), completion: { (imageData,error) in
                            SmileUser.currentUser.profilePic = UIImage(data: imageData!)
                            completion()
                        })
                    })
                }
            })
            
        }
    }
    
    
    static func syncUser(){
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/name").setValue(self.currentUser.name!)
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/signalUID").setValue(self.currentUser.signalUID!)
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/photoURL").setValue(self.currentUser.profilePicURL!)
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/canUpdateLocations").setValue(String.init(describing: self.currentUser.canUpdateLocations!))
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/lastUpdatedLocationTime").setValue(String.init(describing: self.currentUser.lastUpdatedLocationTime!))
        let latLongStr = "(" + "\(self.currentUser.lastLocation!.latitude)" + "," + "\(self.currentUser.lastLocation!.longitude)" + ")"
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/lastLocation").setValue(latLongStr)
        UIDevice.current.isBatteryMonitoringEnabled = true
        SmileBase.userBaseSingleton.child("\(self.currentUser.id!)"+"/batteryLevel").setValue(UIDevice.current.batteryLevel*100)
    }
    
}
