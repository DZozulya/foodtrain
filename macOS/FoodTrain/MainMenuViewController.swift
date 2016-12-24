//
//  ViewController.swift
//  FoodTrain
//
//  Created by Dmytro Zozulia on 11/10/16.
//  Copyright © 2016 FoodTrain. All rights reserved.
//

import Cocoa

let kRowHeight: CGFloat = 50.0

class MainMenuViewController: NSViewController, AutoCompleteTableViewDelegate, NSTextFieldDelegate {

  @IBOutlet weak var tableView: NSTableView!

  @IBOutlet weak var createTrainHeight: NSLayoutConstraint!
  @IBOutlet weak var startTrainHeight: NSLayoutConstraint!

  var kCreateHeight: CGFloat!
  var kStartHeight: CGFloat!

  @IBOutlet weak var trainTitleTextField: AutoCompleteTextField!
  @IBOutlet weak var timeTextField: NSTextField!
  @IBOutlet weak var startTrainButton: NSButton!
  
  var autocompleteBusinesses: [YLPBusiness]?
  var selectedBusiness: YLPBusiness?
  
  var reminderNotification: NSUserNotification?
  var requestSent = false
  
  let trainStartIdentifierFormat = "startNotification%d"
  
  fileprivate static let yelpConsumerKey = {
    return Bundle.main.object(forInfoDictionaryKey: "FT_YELP_CONSUMER_KEY") as! String
  }()
  
  fileprivate static let yelpConsumerSecret = {
    return Bundle.main.object(forInfoDictionaryKey: "FT_YELP_CONSUMER_SECRET") as! String
  }()
  
  fileprivate static let yelpToken = {
    return Bundle.main.object(forInfoDictionaryKey: "FT_YELP_TOKEN") as! String
  }()
  
  fileprivate static let yelpTokenSecret = {
    return Bundle.main.object(forInfoDictionaryKey: "FT_YELP_TOKEN_SECRET") as! String
  }()
  
  
  let yelpClient: YLPClient = YLPClient(consumerKey: MainMenuViewController.yelpConsumerKey,
              consumerSecret: MainMenuViewController.yelpConsumerSecret,
              token: MainMenuViewController.yelpToken,
              tokenSecret: MainMenuViewController.yelpTokenSecret)

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  func notificationTriggeredToJoinFoodTrain(withId identifier:Int) {
    FoodtrainManager.sharedFoodtrainManager.joinFoodTrain(withId: identifier,
                                                          onSuccess: {
                                                            self.updateData()
    },
                                                          onError: {
    })
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    kCreateHeight = self.createTrainHeight.constant
    kStartHeight = self.startTrainHeight.constant
    startTrainButton.isEnabled = false
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(controlTextDidChange(notification:)), name:.NSControlTextDidChange, object: nil)
    center.addObserver(self, selector: #selector(controlTextDidEndEditing(notification:)), name:.NSControlTextDidEndEditing, object: nil)
    trainTitleTextField.tableViewDelegate = self
    self.createTrainHeight.constant = 0.0
    
    self.updateData()
    FoodtrainManager.sharedFoodtrainManager.registerForFoodtrainUpdates {
      self.updateData()
    }
    self.tableView.rowHeight = 1000
  }
  
  func disableOrEnableTopViewsIfCreatedOne() {
    var disabled = false
    FoodtrainManager.sharedFoodtrainManager.getAllFoodtrains().forEach({ (foodtrain) in
      if foodtrain.participants.contains(NSUserName()) {
        DispatchQueue.main.async {
          self.createTrainHeight.constant = 0.0
          self.startTrainHeight.constant = 0.0
        }
        disabled = true
      }
    })
    
    if !disabled && self.createTrainHeight.constant == 0.0 {
      self.startTrainHeight.constant = kStartHeight
    }
  }

  func controlTextDidEndEditing(notification: NSNotification)
  {
    let object = notification.object as! NSTextField
    if object == self.trainTitleTextField {
      if let business = self.selectedBusiness {
        if object.stringValue != self.selectedBusiness?.name {
          self.trainTitleTextField.stringValue = business.name
        }
      } else {
        self.trainTitleTextField.stringValue = ""
      }
      self.trainTitleTextField.autoCompletePopover?.close() 
    }
  }
  
  func controlTextDidChange(notification: NSNotification)
  {
    let object = notification.object as! NSTextField
    if object == self.timeTextField {
      let timeFormat = "[0-2][0-9]\\:[0-6][0-9]"
      let emailTest = NSPredicate(format:"SELF MATCHES %@", timeFormat)
      
      if object.stringValue.characters.count == 5 &&  emailTest.evaluate(with: object.stringValue) && self.selectedBusiness != nil {
        self.startTrainButton.isEnabled = true
      } else {
        self.startTrainButton.isEnabled = false
      }
    }
  }
  
  func textField(textField:NSTextField,completions words:[String],forPartialWordRange charRange:NSRange,indexOfSelectedItem index:Int) ->[String]? {
    let officeLat = Bundle.main.object(forInfoDictionaryKey: "FT_OFFICE_LAT") as! NSNumber
    let officeLong = Bundle.main.object(forInfoDictionaryKey: "FT_OFFICE_LONG") as! NSNumber

    yelpClient.search(with: YLPGeoCoordinate(latitude: officeLat.doubleValue, longitude: officeLong.doubleValue, accuracy: 1.0, altitude: 0.0, altitudeAccuracy: 1.0),
                      currentLatLong: YLPCoordinate(latitude:officeLat.doubleValue, longitude:officeLong.doubleValue),
                      term: textField.stringValue,
                      limit: 15,
                      offset: 0,
                      sort: YLPSortType.bestMatched,
                      completionHandler: {(search, error) in
                        dump(search?.businesses)
                        self.autocompleteBusinesses = search?.businesses
                        let names = search?.businesses.map({ $0.name})
                        DispatchQueue.main.async {
                          self.trainTitleTextField.setMatchesManually(matches: names!)
                        }
    })
    return nil
  }
  
  @objc func didSelectItem(selectedItem: String) {
    autocompleteBusinesses?.forEach({ (business) in
      if business.name == selectedItem {
        self.selectedBusiness = business
        if self.timeTextField.stringValue.characters.count == 5 {
          self.startTrainButton.isEnabled = true
        } else {
          self.startTrainButton.isEnabled = false
        }
      }
    })
  }
  
  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }

  @IBAction func changeTrainViews(_ sender: NSButton?) {
    let showCreate = self.createTrainHeight.constant == 0.0
    self.createTrainHeight.constant = showCreate ? kCreateHeight : 0.0
    self.startTrainHeight.constant = showCreate ? 0.0 : kStartHeight
    self.selectedBusiness = nil
    self.autocompleteBusinesses = nil

    self.timeTextField.stringValue = "12:30"

    if createTrainHeight.constant > 0 && trainTitleTextField.stringValue.characters.count > 0 {
      startTrainButton.isEnabled = true
    }
  }

  @IBAction func savePressed(_ sender: NSButton) {

    let timeComponents = timeTextField.stringValue.components(separatedBy: ":")
    let hour = Int(timeComponents[0])
    let minute = Int(timeComponents[1])
    
    let now = Date()
    let gregorian = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
    var components = gregorian.components([.year, .month, .day, .hour, .minute, .second], from: now)
    
    components.hour = hour
    components.minute = minute
    
    let startTime = gregorian.date(from: components)!
    sender.isEnabled = false

    if let bizId = self.selectedBusiness?.identifier {
      FoodtrainManager.sharedFoodtrainManager.createFoodtrain(restaurantName: trainTitleTextField.stringValue,
                                                              yelpId: bizId,
                                                              startTime: startTime,
                                                              onSuccess: { foodtrainIdentifier in
                                                                DispatchQueue.main.async {
                                                                  self.createTrainHeight.constant = 0.0
                                                                  self.updateData()
                                                                  self.trainTitleTextField.stringValue = ""
                                                                  self.scheduleReminderForFoodtrain(withId: foodtrainIdentifier)
                                                                }
      },
                                                              onError: { error  in
                                                                dump(error)
                                                                sender.isEnabled = false
      })
    }
  }

  func updateData() {
    disableOrEnableTopViewsIfCreatedOne()
    self.tableView.reloadData()
  }

  private func changeHeight(newHeight: CGFloat) {
    let frame = self.view.frame
    self.view.setFrameSize(NSSize(width: frame.size.width, height: newHeight))
    self.view.needsLayout = true
  }
}

extension MainMenuViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return FoodtrainManager.sharedFoodtrainManager.getAllFoodtrains().count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.make(withIdentifier: "TrainCell", owner: self) as! TrainCell
    let foodtrain = FoodtrainManager.sharedFoodtrainManager.getAllFoodtrains()[row]
    cell.wantsLayer = true
    cell.timeTextField.stringValue = foodtrain.shortTimeString()
    cell.restaurantButton.title = foodtrain.restaurantName
    cell.restaurantButton.tag = row
    cell.restaurantButton.target = self
    cell.restaurantButton.action = #selector(linkTapped(sender:))
    cell.descriptionTextField.stringValue = foodtrain.descriptionString()
    cell.joinButton.tag = foodtrain.identifier
    cell.joinButton.target = self
    if foodtrain.userJoined() {
      cell.joinButton.title = "leave"
      cell.layer?.backgroundColor = NSColor(calibratedRed: 232/255, green: 245/255, blue: 218/255, alpha: 1.0).cgColor
      cell.joinButton.action = #selector(unboardButtonPressed(button:))
      cell.joinButton.isHidden = false
    } else {
      cell.layer?.backgroundColor = NSColor.white.cgColor
      let now = Date()
      if FoodtrainManager.sharedFoodtrainManager.isFoodtrainJoinable(foodtrain: foodtrain) && foodtrain.startTime > now {
        cell.joinButton.title = "join"
        cell.layer?.backgroundColor = NSColor.white.cgColor
        cell.joinButton.action = #selector(joinButtonPressed(button:))
        cell.joinButton.isHidden = false
      } else {
        cell.joinButton.isHidden = true
      }
    }
    
    return cell
  }

  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return kRowHeight
  }

  func unboardButtonPressed(button: NSButton) {
    FoodtrainManager.sharedFoodtrainManager.unboardFoodTrain(withId: button.tag,
                                                             onSuccess: {
                                                              //TODO remove Loading Screen
                                                              self.unscheduleReminderForFoodtrain(withId: button.tag)
                                                              self.updateData()
    },
                                                             onError: {
                                                              //TODO remove Loading screen)
    })
  }
  
  @objc func linkTapped(sender: NSButton) {
    if let url = URL(string: "https://www.yelp.com/biz/\(FoodtrainManager.sharedFoodtrainManager.getAllFoodtrains()[sender.tag].yelpId)") {
      NSWorkspace.shared().open(url)
    }
  }

  func joinButtonPressed(button: NSButton) {
    //TODO show loading screen
    FoodtrainManager.sharedFoodtrainManager.joinFoodTrain(withId: button.tag,
                                                          onSuccess: {
                                                            //TODO remove Loading Screen
                                                            self.scheduleReminderForFoodtrain(withId: button.tag)
                                                            self.updateData()
    },
                                                          onError: {
                                                            //TODO remove Loading screen
    })
  }
  
  func scheduleReminderForFoodtrain(withId: NSInteger) {
    if let foodtrain = FoodtrainManager.sharedFoodtrainManager.foodtrain(withId: withId) {
      let message = "Will leave in 5 minutes!"
      let title = "Your foodtrain to \(foodtrain.restaurantName)"
      
      let notification = NSUserNotification.init()
      
      // set the title and the informative text
      notification.title = title
      notification.informativeText = message
      
      notification.soundName = NSUserNotificationDefaultSoundName
      
      notification.hasActionButton = false
      
      
      var components = DateComponents()
      components.setValue(-5, for: .minute)
      
      let newDate = Calendar.current.date(byAdding: components, to: foodtrain.startTime, wrappingComponents: false)
      
      notification.deliveryDate = newDate
      notification.identifier = String(format: trainStartIdentifierFormat, foodtrain.identifier)
      
      self.reminderNotification = notification
      
      NSUserNotificationCenter.default.scheduleNotification(self.reminderNotification!)
    }
  }
  
  func unscheduleReminderForFoodtrain(withId: NSInteger) {
    NSUserNotificationCenter.default.scheduledNotifications.forEach({ (notification) in
      if notification.identifier == String(format: trainStartIdentifierFormat, withId) {
        NSUserNotificationCenter.default.removeScheduledNotification(notification)
      }
    })
      
  }
  
}

extension MainMenuViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
    let viewController = storyboard.instantiateController(withIdentifier: "ParticipantsViewController") as! ParticipantsViewController
    viewController.participants = FoodtrainManager.sharedFoodtrainManager.getAllFoodtrains()[row].participants

    let popover = NSPopover()
    popover.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    popover.behavior = .transient
    popover.contentViewController = viewController

    let rect = NSRect(x: self.tableView.frame.origin.x,
                      y: self.tableView.frame.origin.y + kRowHeight * CGFloat(row),
                      width: self.tableView.frame.size.width,
                      height: kRowHeight)
    popover.show(relativeTo: rect, of: self.tableView, preferredEdge: NSRectEdge.minX)
    return false
  }
}
