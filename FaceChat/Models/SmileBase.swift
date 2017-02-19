//
//  SmileBase.swift
//  FaceChat
//
//  Created by Thomas Hocking on 1/27/17.
//  Copyright © 2017 Thomas Hocking. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class SmileBase: NSObject {
    
        //appID
        static let rootBaseSingleton = FIRDatabase.database().reference(fromURL: "")
        //appID/users
        static let userBaseSingleton = FIRDatabase.database().reference(fromURL: "")
        //appID/groups
        static let groupBaseSingleton = FIRDatabase.database().reference(fromURL: "")
        //appID/fbConvert
        static let fbConvertBaseSingleton = FIRDatabase.database().reference(fromURL: "")
        //storage/images
        static let userProfilePicStorage = FIRStorage.storage().reference(forURL: "")
}
