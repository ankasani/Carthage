//
//  ViewController.swift
//  ParticleSDKExampleApp
//
//  Created by Ido Kleinman on 3/31/16.
//  Copyright © 2016 Particle. All rights reserved.
//

import UIKit
import ParticleDeviceSetupLibrary
import ParticleSDK

class ViewController: UIViewController, SparkSetupMainControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func sparkSetupViewController(controller: SparkSetupMainController!, didFinishWithResult result: SparkSetupMainControllerResult, device: SparkDevice!) {
        
        print("result: \(result), and device: \(device)")
        
    }
    
    @IBAction func invokeSetup(sender: AnyObject) {
        print("Particle Device setup lib V:\(ParticleDeviceSetupLibraryVersionNumber)\nParticle SDK V:\(ParticleSDKVersionNumber)")
        
        // lines required for invoking the Spark Setup wizard
        if let vc = SparkSetupMainController()
        {
            
            // check organization setup mode
            let c = SparkSetupCustomization.sharedInstance()
            c.allowSkipAuthentication = true
            
            vc.delegate = self
            vc.modalPresentationStyle = .FormSheet  // use that for iPad
            self.presentViewController(vc, animated: true, completion: nil)
        }

    }
    
    @IBAction func invokeCloudSDK(sender: AnyObject) {
        self.testCloudSDK()
    }
    
    func testCloudSDK()
    {
        let loginGroup : dispatch_group_t = dispatch_group_create()
        let deviceGroup : dispatch_group_t = dispatch_group_create()
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        let deviceName = "turtle_gerbil" // change to your particular device name
        let functionName = "testFunc"
        let variableName = "testVar"
        var myPhoton : SparkDevice? = nil
        var myEventId : AnyObject?
        
        
        let username = "ido@spark.io"  // change
        let password = "test123"           // change
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_enter(loginGroup);
            dispatch_group_enter(deviceGroup);
            if SparkCloud.sharedInstance().isAuthenticated {
                print("logging out of old session")
                SparkCloud.sharedInstance().logout()
            }
            
            SparkCloud.sharedInstance().loginWithUser(username, password: password, completion: { (error : NSError?) in  // or possibly: .injectSessionAccessToken("ec05695c1b224a262f1a1e92d5fc2de912c467a1")
                if let _ = error {
                    print("Wrong credentials or no internet connectivity, please try again")
                }
                else
                {
                    print("Logged in with user "+username) // or with injected token
                    dispatch_group_leave(loginGroup)
                }
            })
        }
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_wait(loginGroup, DISPATCH_TIME_FOREVER)
            
            // get specific device by name:
            SparkCloud.sharedInstance().getDevices { (sparkDevices:[AnyObject]?, error:NSError?) -> Void in
                if let _=error
                {
                    print("Check your internet connectivity")
                }
                else
                {
                    if let devices = sparkDevices as? [SparkDevice]
                    {
                        for device in devices
                        {
                            if device.name == deviceName
                            {
                                print("found a device with name "+deviceName+" in your account")
                                myPhoton = device
                                dispatch_group_leave(deviceGroup)
                            }
                            
                        }
                        if (myPhoton == nil)
                        {
                            print("device with name "+deviceName+" was not found in your account")
                        }
                    }
                }
            }
        }
        
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_wait(deviceGroup, DISPATCH_TIME_FOREVER)
            dispatch_group_enter(deviceGroup);
            
            print("subscribing to event...");
            var gotFirstEvent : Bool = false
            myEventId = myPhoton!.subscribeToEventsWithPrefix("test", handler: { (event: SparkEvent?, error:NSError?) -> Void in
                if (!gotFirstEvent) {
                    print("Got first event: "+event!.event)
                    gotFirstEvent = true
                    dispatch_group_leave(deviceGroup)
                } else {
                    print("Got event: "+event!.event)
                }
            });
        }
        
        
        // calling a function
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_wait(deviceGroup, DISPATCH_TIME_FOREVER) // 5
            dispatch_group_enter(deviceGroup);
            
            let funcArgs = ["D7",1]
            myPhoton!.callFunction(functionName, withArguments: funcArgs) { (resultCode : NSNumber?, error : NSError?) -> Void in
                if (error == nil) {
                    print("Successfully called function "+functionName+" on device "+deviceName)
                    dispatch_group_leave(deviceGroup)
                } else {
                    print("Failed to call function "+functionName+" on device "+deviceName)
                }
            }
        }
        
        
        // reading a variable
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_wait(deviceGroup, DISPATCH_TIME_FOREVER) // 5
            dispatch_group_enter(deviceGroup);
            
            myPhoton!.getVariable(variableName, completion: { (result:AnyObject?, error:NSError?) -> Void in
                if let _=error
                {
                    print("Failed reading variable "+variableName+" from device")
                }
                else
                {
                    if let res = result as? Int
                    {
                        print("Variable "+variableName+" value is \(res)")
                        dispatch_group_leave(deviceGroup)
                    }
                }
            })
        }
        
        
        // get device variables and functions
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_wait(deviceGroup, DISPATCH_TIME_FOREVER) // 5
            dispatch_group_enter(deviceGroup);
            
            let myDeviceVariables : Dictionary? = myPhoton!.variables as Dictionary<String,String>
            print("MyDevice first Variable is called \(myDeviceVariables!.keys.first) and is from type \(myDeviceVariables?.values.first)")
            
            let myDeviceFunction = myPhoton!.functions
            print("MyDevice first function is called \(myDeviceFunction.first)")
            dispatch_group_leave(deviceGroup)
        }
        
        // logout
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // logging in
            dispatch_group_wait(deviceGroup, DISPATCH_TIME_FOREVER) // 5
            
            if let eId = myEventId {
                myPhoton!.unsubscribeFromEventWithID(eId)
            }
            SparkCloud.sharedInstance().logout()
            
            print("logged out")
        }
        
 
        
        
        
    }
    
    


}

