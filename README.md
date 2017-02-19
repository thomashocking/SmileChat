# SmileChat
Facial Detection/Compter Vision Chat

Using https://github.com/aaronabentheuer/AAFaceDetection (Visage) that has been coverted to Swift 3.0

[![License](http://img.shields.io/badge/License-MIT-green.svg?style=flat)](https://github.com/thomashocking/SmileChat/master/LICENSE)
[![Swift 3](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://swift.org)
[![Twitter: @tommahhockin](https://img.shields.io/badge/Contact-Twitter-blue.svg?style=flat)](https://twitter.com/tommahhockin)

* SmileChat lets you use your face to show how you feel while you chat with friends.

* It's currently using the above repo to classify facial states and provide an approximate result.

* It has a few UI issues (updates labels very quickly, quirks in basic functionality), but it is mostly a proof of concept.

* Supports Facebook login, but other types are welcome to be added.

<h3 align="center">
<img src="SmileLast.png" alt="Screenshot of Smile Chat for iOS" />
</h3>

## Getting Started

To get started and run the app, you need to follow these steps (and possibly more):

1. Open the SmileChat workspace in Xcode.
2. Change the Bundle Identifier to match your domain.
3. Go to [Firebase](https://firebase.google.com) and create new project.
4. Select "Add Firebase to your iOS app" option, type the bundle Identifier & click continue.
5. Download "GoogleService-Info.plist" file and add to the project. Make sure file name is "GoogleService-Info.plist".
6. Edit Model files to make sure they conform to schema
7. Go to [Firebase Console](https://console.firebase.google.com), select your project, choose "Authentication" from left menu, select "SIGN-IN METHOD" and enable Facebook option and follow tutorial to setup Facebook on Firebase & Facebook Dev sites.
8. Use on device to make use of front facing camera.

## Compatibility

This project is written in Swift 3.0 and requires Xcode 8.2 to build and run.


## Author

* [Thomas Hocking](https://twitter.com/tommahhockin)

## License

Copyright 2017 Thomas Hocking.

Licensed under MIT License: https://opensource.org/licenses/MIT
