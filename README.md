#Aura
####Ayla Networks' iOS Demo Application

Supports iOS version 9.0 and above;  
Supports CocoaPods version 1.0.0 and above.  No longer supports version 0.39.0.  

#Getting Started
The following steps should be run in Terminal.

1. Clone the repository into your working directory:

    >```git clone https://github.com/AylaNetworks/iOS_Aura_Public```
    
2.  Install [Cocoapods](https://cocoapods.org) if you do not already have it: 

    >```gem install cocoapods```

    Note: This version of Aura only supports Cocoapods version 1.0.0 and above. If you currently have a version of Cocoapods lower than 1.0.0 (such as the previously supported and incompatible version 0.39.0, please enter the following command to upgrade.
    >```gem upgrade cocoapods```

3. Then run the following command within the Aura folder: 

    >```pod install```
 
4. (Optional) Set the AYLA_SDK_BRANCH environment variable to the name of the AylaSDK branch you want to include. If the variable is unset, Cocoapods will default to the latest SDK release branch.

    >```export AYLA_SDK_BRANCH=release/5.2.00```
    
5. Install Pods

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

#Release Notes

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
