#Aura
##Ayla Networks iOS Demo Application

#Getting Started
The following steps should be run in Terminal.

1. Clone the repository into your working directory and check out the develop branch:

    >```git clone https://github.com/AylaNetworks/iOS_Aura```
    
    >```git checkout develop```

2.  Install [Cocoapods](https://cocoapods.org) if you do not already have it: 

    >```gem install cocoapods```

3. Then run the following command within the Aura folder: 

    >```pod install```
 
4. (Optional) Set AYLA_SDK_BRANCH environment variable to the name of the AylaSDK branch you want to include. 
    If the variable is un-set, The Cocoapods will default to the latest SDK release branch which is the same as 'main'.

    >``` export AYLA_SDK_BRANCH=release/5.0.00```
    
5. Install Pods

    >``` pod install```
    
Once the Pods have been installed correctly, Cocoapods will generate a `iOS_Aura.xcworkspace` file.
When opening Aura in Xcode, be sure to _only open the .xcworkspace_ file.

##Documentation

Supported iOS version: 8 and higher;  
AppleDoc for the libraries is available. After the Pods are installed, follow the instructions located at:  
  \<repo directory\>/Pods/iOS_AylaSDK/README.md

##Dependencies

- AFNetworking ([License](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE))
- CocoaAsyncSocket ([License](https://github.com/robbiehanson/CocoaAsyncSocket/wiki/License))
- CocoaHTTPServer ([License](https://github.com/robbiehanson/CocoaHTTPServer/blob/master/LICENSE.txt))
- SocketRocket ([License](https://github.com/square/SocketRocket/blob/master/LICENSE))

#Release Notes

5.0.00    04/21/16
------
initial release
