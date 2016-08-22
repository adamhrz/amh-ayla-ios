#Aura
####Ayla Networks' iOS Demo Application

Supports iOS version 9.0 and above;   

#Getting Started
The following steps should be run in Terminal.

1. Clone the repository into your working directory:

    >```git clone https://github.com/AylaNetworks/iOS_Aura_Public```
    
2.  Install [Cocoapods](https://cocoapods.org) if you do not already have it: 

    >```gem install cocoapods```

    Note: This version of Aura now supports Cocoapods version 1.0.0 and above. If you currently have a version of Cocoapods lower than 1.0.0, it may work, but it is recommended to upgrade using the following command.
    >```gem upgrade cocoapods```
 
3. (Optional) Set the AYLA_SDK_BRANCH environment variable to the name of the AylaSDK branch you want to include. If the variable is unset, Cocoapods will default to the latest SDK release branch.

    >```export AYLA_SDK_BRANCH=release/5.2.00```
    
4. Install Pods by running the following command within the Aura folder:

    >```pod install```
    
Once the Pods have been installed correctly, Cocoapods will generate a `iOS_Aura.xcworkspace` file.
When opening Aura in Xcode, be sure to _only open the .xcworkspace_ file.

##Documentation

The Ayla SDK is documented using [AppleDoc](https://github.com/tomaz/appledoc/).  To build the SDK docset, after the Pods are installed, follow the instructions located at: \<repo directory\>/Pods/iOS_AylaSDK/README.md

##Dependencies

- AFNetworking ([License](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE))
- CocoaAsyncSocket ([License](https://github.com/robbiehanson/CocoaAsyncSocket/wiki/License))
- CocoaHTTPServer ([License](https://github.com/robbiehanson/CocoaHTTPServer/blob/master/LICENSE.txt))
- SocketRocket ([License](https://github.com/square/SocketRocket/blob/master/LICENSE))
- SwiftKeychainWrapper ([License](https://github.com/jrendel/SwiftKeychainWrapper/blob/develop/LICENSE))
- PDKeychainBindingsController ([License](https://github.com/carlbrown/PDKeychainBindingsController/blob/master/LICENSE))
- SAMKeychain ([License](https://github.com/soffes/SAMKeychain/blob/master/LICENSE))

##Contribute your code

If you would like to contribute your own code change to our project, please submit pull requests against the "incoming" branch on Github. We will review and approve your pull requests if appropriate.

#Release Notes

v5.2.00    2016-08-2;2
------
New & Improved
- Offline (LAN) sign-in and LAN device connectivity using cached data
- Generic Gateway and Node registration using Raspberry Pi
- Update account email address
- Device property notifications for email, sms, and push
- Change device time zones
- Device Sharing
- Device Schedules

Bug Fixes & Chores
- Automated testing via Jenkins, Appium with test cases via Zephyr
- Using Fastlane for automated build and release
- All 5.1.0x hot-fixes
- UI improvements
- Built using the latest SDK

v5.1.00    2016-06-27
------
New Features:
- Offline (LAN) sign-in and LAN device connectivity using cached data
- Generic Gateway and Node registration
- Change device time zones
- Device Sharing
- Device Schedules
- Notifications for properties: push, email, and sms

Enhancements and Bug Fixes:
- Code updates to support 5.1.00 Ayla Mobile SDK

v5.0.02    2016-06-15
------
- add release notes about CocoaPods version requirement

v5.0.01    2016-05-24
------
- work with iOS_AylaSDK 5.0.01

v5.0.00    2016-04-22
------
-initial release (requires Ayla SDK v5.0.00)
