# Aura

#### Ayla Networks' iOS Demo Application

Supports iOS version 9.0 and above;   

# Getting Started

The following steps should be run in Terminal.

1. Clone the repository into your working directory:
    
    ```bash
    $ git clone https://github.com/AylaNetworks/iOS_Aura_Public
    ```

2.  Install [Cocoapods](https://cocoapods.org) if you do not already have it: 

     ```bash
     $ gem install cocoapods
     ```

    Note: This version of Aura now supports Cocoapods version 1.1.1 and above. If you currently have a version of Cocoapods lower than 1.1.1, it may work, but it is recommended to upgrade using the following command.

    ```bash
    $ gem upgrade cocoapods
    ```
 
3. (Optional) Set the AYLA_SDK_BRANCH environment variable to the name of the AylaSDK branch you want to include. If the variable is unset, Cocoapods will default to the latest SDK release branch.

    ```bash
    $ export AYLA_SDK_BRANCH=release/5.5.00
    ```
    
4. Install Pods by running the following command within the Aura folder:

    ```bash
    $ pod install
    ```
    
Once the Pods have been installed correctly, Cocoapods will generate a `iOS_Aura.xcworkspace` file.
When opening Aura in Xcode, be sure to _only open the .xcworkspace_ file. If it asks whether to convert to current Swift syntax, please answer No. If it asks whether to perform changes for watchOS 2, please answer No.

## Documentation

The 'doc' folder contains documentation specific to Aura features.

#### SDK Documentation
The Ayla SDK is documented using [appledoc](https://github.com/tomaz/appledoc/). This program may be installed by compiling [from source](https://github.com/tomaz/appledoc/), or by using [Homebrew](http://brew.sh) 
```bash
brew install appledoc
``` 

With `appledoc` installed, you may run the 'Documentation' target within the `iOS_Aura.xcworkspace` file to compile and install the Ayla SDK docset. This will open an interactive HTML-based API guide for the Ayla SDK and allow for SDK-related inline help within Xcode. 

## Dependencies

- AFNetworking ([License](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE))
- ActionSheetPicker-3.0 ([License](https://github.com/skywinder/ActionSheetPicker-3.0/blob/master/LICENSE))
- CocoaAsyncSocket ([License](https://github.com/robbiehanson/CocoaAsyncSocket/wiki/License))
- CocoaHTTPServer ([License](https://github.com/robbiehanson/CocoaHTTPServer/blob/master/LICENSE.txt))
- Google/SignIn ([License](https://github.com/googlesamples/google-services/blob/master/LICENSE))
- SocketRocket ([License](https://github.com/square/SocketRocket/blob/master/LICENSE))
- SwiftKeychainWrapper ([License](https://github.com/jrendel/SwiftKeychainWrapper/blob/develop/LICENSE))
- PDKeychainBindingsController ([License](https://github.com/carlbrown/PDKeychainBindingsController/blob/master/LICENSE))
- SAMKeychain ([License](https://github.com/soffes/SAMKeychain/blob/master/LICENSE))

## Contribute your code

If you would like to contribute your own code change to our project, please submit pull requests against the "incoming" branch on Github. We will review and approve your pull requests if appropriate.

## Requirements
- Xcode: 8.3
- CocoaPods: 1.1.1
- iOS 9.0 or higher

# Release Notes

### v5.4.02     2017-03-17
- Support SDK 5.4.02

### v5.4.01     2017-03-14
- Fix pod install bug

### v5.4.00     2017-02-02
#### New & Improved App
- Support for iOS_AylaSDK 5.4.00
- Improved WiFi Setup status
- Support for iPhone 7 using iOS 10.2+
- New file preview support in AylaDatapointBlob class
- New 'About' menu with version and diagnostic information

#### Bug Fixes & Chores
- Built using iOS_AylaSDK_Public version 5.4.00
- Includes are previous hot fixes

### v5.3.01     2016-11-11
- support iOS_AylaSDK 5.3.01

### v5.3.00     2016-10-22
#### New & Improved
- Support for iOS_AylaSDK 5.3.00
- New iOS 10 support
- New SDK Universal static library build target
- New Aura OEM Config: Just for IoT HW Engineers - Use core Aura features without knowing

#### Objective-C, Java, or Swift!
- New Aura Test Runner: Network Profiler - Easily monitor round-trip network times
- Improved feedback during WiFi Setup

#### Bug Fixes & Chores
- All 5.2.xx hot-fixes

### v5.2.00    2016-08-22

#### New & Improved
- Offline (LAN) sign-in and LAN device connectivity using cached data
- Generic Gateway and Node registration using Raspberry Pi
- Update account email address
- Device property notifications for email, sms, and push
- Change device time zones
- Device Sharing
- Device Schedules
- New LAN OTA platform feature support

#### Bug Fixes & Chores
- Automated testing via Jenkins, Appium with test cases via Zephyr
- Using Fastlane for automated build and release
- All 5.1.0x hot-fixes
- UI improvements
- Built using the latest SDK

### v5.1.00    2016-06-27

#### New Features:
- Offline (LAN) sign-in and LAN device connectivity using cached data
- Generic Gateway and Node registration
- Change device time zones
- Device Sharing
- Device Schedules
- Notifications for properties: push, email, and sms

#### Enhancements and Bug Fixes:
- Code updates to support 5.1.00 Ayla Mobile SDK

### v5.0.02    2016-06-15
- add release notes about CocoaPods version requirement

### v5.0.01    2016-05-24
- work with iOS_AylaSDK 5.0.01

## v5.0.00    2016-04-22
- initial release (requires Ayla SDK v5.0.00)

