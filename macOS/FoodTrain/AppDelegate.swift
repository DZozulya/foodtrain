//
//  AppDelegate.swift
//  FoodTrain
//
//  Created by Dmytro Zozulia on 11/10/16.
//  Copyright © 2016 FoodTrain. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

  var statusItem: NSStatusItem!
  let mainMenu = NSPopover()
  var mainViewController: MainMenuViewController?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    statusItem.image = NSImage(named: "TrainMenuIcon")
    statusItem.image?.isTemplate = true
    statusItem.action = #selector(togglePopover)
    
    FoodtrainManager.sharedFoodtrainManager.registerForFoodtrainUpdates {}
    let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
    mainViewController = storyboard.instantiateController(withIdentifier: "MainMenuViewController") as? MainMenuViewController
    mainMenu.contentViewController = mainViewController
    NSUserNotificationCenter.default.delegate = self
    mainMenu.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    
    if !applicationIsInStartUpItems() {
      toggleLaunchAtStartup()
    }
    
    NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(AppDelegate.wokeUpNotificationReceived(notification:)), name: .NSWorkspaceDidWake, object: nil)
  }
  
  func wokeUpNotificationReceived(notification: NSNotification) {
    FoodtrainManager.sharedFoodtrainManager.restartPollingIfNecessary()
  }
  
  func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
    let identifier = notification.userInfo!["identifier"] as! Int
    mainViewController?.notificationTriggeredToJoinFoodTrain(withId: identifier)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func showPopover(sender: AnyObject?) {
    if let button = statusItem.button {
      mainMenu.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
    }
  }

  func closePopover(sender: AnyObject?) {
    mainMenu.performClose(sender)
  }

  func togglePopover(sender: AnyObject?) {
    let event = NSApp.currentEvent
    if (event?.modifierFlags.contains(NSAlternateKeyMask))! {
      NSApplication.shared().terminate(self)
    }
    if mainMenu.isShown {
      closePopover(sender: sender)
    } else {
      showPopover(sender: sender)
    }
  }
  
  func userNotificationCenter(_ center : NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
    return true
  }
  
  
  
  func applicationIsInStartUpItems() -> Bool {
    return (itemReferencesInLoginItems().existingReference != nil)
  }
  
  func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
    var itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.allocate(capacity: 1)
    if let appUrl : NSURL = NSURL.fileURL(withPath: Bundle.main.bundlePath) as NSURL? {
      let loginItemsRef = LSSharedFileListCreate(
        nil,
        kLSSharedFileListSessionLoginItems.takeRetainedValue(),
        nil
        ).takeRetainedValue() as LSSharedFileList?
      if loginItemsRef != nil {
        let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
        print("There are \(loginItems.count) login items")
        let lastItemRef: LSSharedFileListItem = loginItems.lastObject as! LSSharedFileListItem
        for i in 0 ..< loginItems.count {
          let currentItemRef: LSSharedFileListItem = loginItems.object(at: i) as! LSSharedFileListItem
          if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
            if let urlRef: NSURL =  itemUrl.pointee?.takeRetainedValue() {
              print("URL Ref: \(urlRef.lastPathComponent)")
              if urlRef.isEqual(appUrl) {
                return (currentItemRef, lastItemRef)
              }
            }
          } else {
            print("Unknown login application")
          }
        }
        //The application was not found in the startup list
        return (nil, lastItemRef)
      }
    }
    return (nil, nil)
  }
  
  func toggleLaunchAtStartup() {
    let itemReferences = itemReferencesInLoginItems()
    let shouldBeToggled = (itemReferences.existingReference == nil)
    let loginItemsRef = LSSharedFileListCreate(
      nil,
      kLSSharedFileListSessionLoginItems.takeRetainedValue(),
      nil
      ).takeRetainedValue() as LSSharedFileList?
    if loginItemsRef != nil {
      if shouldBeToggled {
        if let appUrl : CFURL = NSURL.fileURL(withPath: Bundle.main.bundlePath) as CFURL? {
          LSSharedFileListInsertItemURL(
            loginItemsRef,
            itemReferences.lastReference,
            nil,
            nil,
            appUrl,
            nil,
            nil
          )
          print("Application was added to login items")
        }
      } else {
        if let itemRef = itemReferences.existingReference {
          LSSharedFileListItemRemove(loginItemsRef,itemRef);
          print("Application was removed from login items")
        }
      }
    }
  }
  
}

