//
//  AppDelegate.swift
//  BaoKanIOS
//
//  Created by jianfeng on 15/12/20.
//  Copyright © 2015年 六阿哥. All rights reserved.
//

import UIKit
import CoreData
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        setupGlobalStyle()        // 配置全局样式
        setupRootViewController() // 配置控制器
        setupKeyBoardManager()    // 配置键盘管理者
        setupJPush(application, launchOptions: launchOptions) // 配置极光推送
        
        return true
    }
    
    /**
     配置键盘管理者
     */
    private func setupKeyBoardManager() {
        IQKeyboardManager.sharedManager().enable = true
    }
    
    /**
     配置极光推送
     */
    private func setupJPush(application: UIApplication, launchOptions: [NSObject: AnyObject]?) {
        JPUSHService.registerForRemoteNotificationTypes(UIUserNotificationType.Badge.rawValue | UIUserNotificationType.Alert.rawValue | UIUserNotificationType.Sound.rawValue, categories: nil)
        JPUSHService.setupWithOption(launchOptions, appKey: JPUSH_APP_KEY, channel: JPUSH_CHANNEL, apsForProduction: JPUSH_IS_PRODUCTION)
        JPUSHService.crashLogON()
        
        if let options = launchOptions {
            let userInfo = options[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject]
            if let info = userInfo {
                application.applicationIconBadgeNumber = 0
                NSNotificationCenter.defaultCenter().postNotificationName("didReceiveRemoteNotificationOfJPush", object: info)
            }
        }
    }
    
    /**
     全局样式
     */
    private func setupGlobalStyle() {
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        JFProgressHUD.setupHUD() // 配置HUD
    }
    
    /**
     根控制器
     */
    private func setupRootViewController() {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = JFTabBarController()
        window?.makeKeyAndVisible()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("did Fail To Register For Remote Notifications With Error: \(error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler(UIBackgroundFetchResult.NewData)
        
        if application.applicationState == .Background || application.applicationState == .Inactive {
            application.applicationIconBadgeNumber = 0
            NSNotificationCenter.defaultCenter().postNotificationName("didReceiveRemoteNotificationOfJPush", object: userInfo)
        } else if application.applicationState == .Active {
            application.applicationIconBadgeNumber = 0
            
            let message = userInfo["aps"]!["alert"] as! String
            let alertC = UIAlertController(title: "收到新的消息", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let confrimAction = UIAlertAction(title: "查看", style: UIAlertActionStyle.Destructive, handler: { (action) in
                NSNotificationCenter.defaultCenter().postNotificationName("didReceiveRemoteNotificationOfJPush", object: userInfo)
            })
            let cancelAction = UIAlertAction(title: "忽略", style: UIAlertActionStyle.Default, handler: { (action) in
                
            })
            alertC.addAction(confrimAction)
            alertC.addAction(cancelAction)
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertC, animated: true, completion: nil)
        }
        
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        JPUSHService.showLocalNotificationAtFront(notification, identifierKey: nil)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        
    }

    func applicationWillTerminate(application: UIApplication) {
        self.saveContext()
    }

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = NSBundle.mainBundle().URLForResource("BaoKanIOS", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

