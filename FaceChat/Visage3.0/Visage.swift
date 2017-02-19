//
//  Visage.swift
//  FaceDetection
//
//  Created by Julian Abentheuer on 21.12.14.
//  Copyright (c) 2014 Aaron Abentheuer. All rights reserved.
//
import UIKit
import CoreImage
import AVFoundation
import ImageIO

class Visage: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    enum DetectorAccuracy {
        case batterySaving
        case higherPerformance
    }
    
    enum CameraDevice {
        case iSightCamera
        case faceTimeCamera
    }
    
    var onlyFireNotificatonOnStatusChange : Bool = true
    var visageCameraView : UIView = UIView()
    
    //Private properties of the detected face that can be accessed (read-only) by other classes.
    fileprivate(set) var faceDetected : Bool?
    fileprivate(set) var faceBounds : CGRect?
    fileprivate(set) var faceAngle : CGFloat?
    fileprivate(set) var faceAngleDifference : CGFloat?
    fileprivate(set) var leftEyePosition : CGPoint?
    fileprivate(set) var rightEyePosition : CGPoint?
    
    fileprivate(set) var mouthPosition : CGPoint?
    fileprivate(set) var hasSmile : Bool?
    fileprivate(set) var isBlinking : Bool?
    fileprivate(set) var isWinking : Bool?
    fileprivate(set) var leftEyeClosed : Bool?
    fileprivate(set) var rightEyeClosed : Bool?
    
    //Notifications you can subscribe to for reacting to changes in the detected properties.
    fileprivate let visageNoFaceDetectedNotification = Notification(name: Notification.Name(rawValue: "visageNoFaceDetectedNotification"), object: nil)
    fileprivate let visageFaceDetectedNotification = Notification(name: Notification.Name(rawValue: "visageFaceDetectedNotification"), object: nil)
    fileprivate let visageSmilingNotification = Notification(name: Notification.Name(rawValue: "visageHasSmileNotification"), object: nil)
    fileprivate let visageNotSmilingNotification = Notification(name: Notification.Name(rawValue: "visageHasNoSmileNotification"), object: nil)
    fileprivate let visageBlinkingNotification = Notification(name: Notification.Name(rawValue: "visageBlinkingNotification"), object: nil)
    fileprivate let visageNotBlinkingNotification = Notification(name: Notification.Name(rawValue: "visageNotBlinkingNotification"), object: nil)
    fileprivate let visageWinkingNotification = Notification(name: Notification.Name(rawValue: "visageWinkingNotification"), object: nil)
    fileprivate let visageNotWinkingNotification = Notification(name: Notification.Name(rawValue: "visageNotWinkingNotification"), object: nil)
    fileprivate let visageLeftEyeClosedNotification = Notification(name: Notification.Name(rawValue: "visageLeftEyeClosedNotification"), object: nil)
    fileprivate let visageLeftEyeOpenNotification = Notification(name: Notification.Name(rawValue: "visageLeftEyeOpenNotification"), object: nil)
    fileprivate let visageRightEyeClosedNotification = Notification(name: Notification.Name(rawValue: "visageRightEyeClosedNotification"), object: nil)
    fileprivate let visageRightEyeOpenNotification = Notification(name: Notification.Name(rawValue: "visageRightEyeOpenNotification"), object: nil)
    
    //Private variables that cannot be accessed by other classes in any way.
    fileprivate var faceDetector : CIDetector?
    fileprivate var videoDataOutput : AVCaptureVideoDataOutput?
    fileprivate var videoDataOutputQueue : DispatchQueue?
    fileprivate var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var captureSession : AVCaptureSession = AVCaptureSession()
    fileprivate let notificationCenter : NotificationCenter = NotificationCenter.default
    fileprivate var currentOrientation : Int?
    
    init(cameraPosition : CameraDevice, optimizeFor : DetectorAccuracy) {
        super.init()
        
        currentOrientation = convertOrientation(UIDevice.current.orientation)
        
        switch cameraPosition {
        case .faceTimeCamera : self.captureSetup(AVCaptureDevicePosition.front)
        case .iSightCamera : self.captureSetup(AVCaptureDevicePosition.back)
        }
        
        var faceDetectorOptions : [String : AnyObject]?
        
        switch optimizeFor {
        case .batterySaving : faceDetectorOptions = [CIDetectorAccuracy : CIDetectorAccuracyLow as AnyObject]
        case .higherPerformance : faceDetectorOptions = [CIDetectorAccuracy : CIDetectorAccuracyHigh as AnyObject]
        }
        
        self.faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: faceDetectorOptions)
    }
    
    //MARK: SETUP OF VIDEOCAPTURE
    func beginFaceDetection() {
        self.captureSession.startRunning()
    }
    
    func endFaceDetection() {
        self.captureSession.stopRunning()
    }
    
    fileprivate func captureSetup (_ position : AVCaptureDevicePosition) {
        var captureError : NSError?
        var captureDevice : AVCaptureDevice!
        
        for testedDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo){
            if ((testedDevice as AnyObject).position == position) {
                captureDevice = testedDevice as! AVCaptureDevice
            }
        }
        
        if (captureDevice == nil) {
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        var deviceInput : AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            captureError = error
            deviceInput = nil
        }
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        if (captureError == nil) {
            if (captureSession.canAddInput(deviceInput)) {
                captureSession.addInput(deviceInput)
            }
            
            self.videoDataOutput = AVCaptureVideoDataOutput()
            self.videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
            self.videoDataOutput!.alwaysDiscardsLateVideoFrames = true
            self.videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: [])
            self.videoDataOutput!.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue!)
            
            if (captureSession.canAddOutput(self.videoDataOutput)) {
                captureSession.addOutput(self.videoDataOutput)
            }
        }
        
        visageCameraView.frame = UIScreen.main.bounds
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = UIScreen.main.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        visageCameraView.layer.addSublayer(previewLayer!)
    }
    
    var options : [String : AnyObject]?
    
    //MARK: CAPTURE-OUTPUT/ANALYSIS OF FACIAL-FEATURES
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        
        options = [CIDetectorSmile : true as AnyObject, CIDetectorEyeBlink: true as AnyObject, CIDetectorImageOrientation : 6 as AnyObject]
        
        let features = self.faceDetector!.features(in: sourceImage, options: options)
        
        if (features.count != 0) {
            
            if (onlyFireNotificatonOnStatusChange == true) {
                if (self.faceDetected == false) {
                    notificationCenter.post(visageFaceDetectedNotification)
                }
            } else {
                notificationCenter.post(visageFaceDetectedNotification)
            }
            
            self.faceDetected = true
            
            for feature in features as! [CIFaceFeature] {
                faceBounds = feature.bounds
                
                if (feature.hasFaceAngle) {
                    
                    if (faceAngle != nil) {
                        faceAngleDifference = CGFloat(feature.faceAngle) - faceAngle!
                    } else {
                        faceAngleDifference = CGFloat(feature.faceAngle)
                    }
                    
                    faceAngle = CGFloat(feature.faceAngle)
                }
                
                if (feature.hasLeftEyePosition) {
                    leftEyePosition = feature.leftEyePosition
                }
                
                if (feature.hasRightEyePosition) {
                    rightEyePosition = feature.rightEyePosition
                }
                
                if (feature.hasMouthPosition) {
                    mouthPosition = feature.mouthPosition
                }
                
                if (feature.hasSmile) {
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.hasSmile == false) {
                            notificationCenter.post(visageSmilingNotification)
                        }
                    } else {
                        notificationCenter.post(visageSmilingNotification)
                    }
                    
                    hasSmile = feature.hasSmile
                    
                } else {
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.hasSmile == true) {
                            notificationCenter.post(visageNotSmilingNotification)
                        }
                    } else {
                        notificationCenter.post(visageNotSmilingNotification)
                    }
                    
                    hasSmile = feature.hasSmile
                }
                
                if (feature.leftEyeClosed || feature.rightEyeClosed) {
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.isWinking == false) {
                            notificationCenter.post(visageWinkingNotification)
                        }
                    } else {
                        notificationCenter.post(visageWinkingNotification)
                    }
                    
                    isWinking = true
                    
                    if (feature.leftEyeClosed) {
                        if (onlyFireNotificatonOnStatusChange == true) {
                            if (self.leftEyeClosed == false) {
                                notificationCenter.post(visageLeftEyeClosedNotification)
                            }
                        } else {
                            notificationCenter.post(visageLeftEyeClosedNotification)
                        }
                        
                        leftEyeClosed = feature.leftEyeClosed
                    }
                    if (feature.rightEyeClosed) {
                        if (onlyFireNotificatonOnStatusChange == true) {
                            if (self.rightEyeClosed == false) {
                                notificationCenter.post(visageRightEyeClosedNotification)
                            }
                        } else {
                            notificationCenter.post(visageRightEyeClosedNotification)
                        }
                        
                        rightEyeClosed = feature.rightEyeClosed
                    }
                    if (feature.leftEyeClosed && feature.rightEyeClosed) {
                        if (onlyFireNotificatonOnStatusChange == true) {
                            if (self.isBlinking == false) {
                                notificationCenter.post(visageBlinkingNotification)
                            }
                        } else {
                            notificationCenter.post(visageBlinkingNotification)
                        }
                        
                        isBlinking = true
                    }
                } else {
                    
                    if (onlyFireNotificatonOnStatusChange == true) {
                        if (self.isBlinking == true) {
                            notificationCenter.post(visageNotBlinkingNotification)
                        }
                        if (self.isWinking == true) {
                            notificationCenter.post(visageNotWinkingNotification)
                        }
                        if (self.leftEyeClosed == true) {
                            notificationCenter.post(visageLeftEyeOpenNotification)
                        }
                        if (self.rightEyeClosed == true) {
                            notificationCenter.post(visageRightEyeOpenNotification)
                        }
                    } else {
                        notificationCenter.post(visageNotBlinkingNotification)
                        notificationCenter.post(visageNotWinkingNotification)
                        notificationCenter.post(visageLeftEyeOpenNotification)
                        notificationCenter.post(visageRightEyeOpenNotification)
                    }
                    
                    isBlinking = false
                    isWinking = false
                    leftEyeClosed = feature.leftEyeClosed
                    rightEyeClosed = feature.rightEyeClosed
                }
            }
        } else {
            if (onlyFireNotificatonOnStatusChange == true) {
                if (self.faceDetected == true) {
                    notificationCenter.post(visageNoFaceDetectedNotification)
                }
            } else {
                notificationCenter.post(visageNoFaceDetectedNotification)
            }
            
            self.faceDetected = false
        }
    }
    
    //TODO: 🚧 HELPER TO CONVERT BETWEEN UIDEVICEORIENTATION AND CIDETECTORORIENTATION 🚧
    fileprivate func convertOrientation(_ deviceOrientation: UIDeviceOrientation) -> Int {
        var orientation: Int = 0
        switch deviceOrientation {
        case .portrait:
            orientation = 6
        case .portraitUpsideDown:
            orientation = 2
        case .landscapeLeft:
            orientation = 3
        case .landscapeRight:
            orientation = 4
        default : orientation = 1
        }
        return 6
    }
}
