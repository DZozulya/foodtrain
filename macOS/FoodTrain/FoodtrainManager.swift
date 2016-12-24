//
//  FoodtrainManager.swift
//  FoodTrain
//
//  Created by Leon Stellbrink on 11/10/16.
//  Copyright © 2016 FoodTrain. All rights reserved.
//

import Foundation


class FoodtrainManager {
  
  static let sharedFoodtrainManager = FoodtrainManager()
  
  private var onFoodtrainUpdates: (() -> ())?
  private var foodtrains: [Foodtrain] = []
  private var pollingTimer: Timer?
  
  func getAllFoodtrains() -> [Foodtrain] {
    return foodtrains
  }
  
  func foodtrain(withId id: Int) -> Foodtrain? {
    var foodtrainToReturn: Foodtrain? = nil
    self.foodtrains.forEach { (foodtrain) in
      if foodtrain.identifier == id {
        foodtrainToReturn = foodtrain
      }
    }
    return foodtrainToReturn
  }
  
  func registerForFoodtrainUpdates(onFoodtrainUpdates:@escaping () -> ()) {
    self.onFoodtrainUpdates = onFoodtrainUpdates
  }
  
  func unregisterForNewFoodtrains() {
    onFoodtrainUpdates = nil
  }
  
  func createFoodtrain(restaurantName: String,
                       yelpId: String,
                       startTime: Date,
                       onSuccess: @escaping (Int) -> (),
                       onError: @escaping (Error) -> ()) {
    Foodtrain.createFoodtrain(creator: NSUserName(),
                              restaurantName: restaurantName,
                              yelpId: yelpId,
                              startTime: startTime,
                              onSuccess: { foodtrain in
                                self.foodtrains.append(foodtrain)
                                self.sortFoodtrains()
                                onSuccess(foodtrain.identifier)
    },
                              onError: { error in
                                onError(error)
    } )
    
  }
  
  func joinFoodTrain(withId id: Int,
                     onSuccess: @escaping () -> (),
                     onError: @escaping () -> () ) {
    foodtrains.forEach { (foodtrain) in
      if foodtrain.identifier == id {
        self.joinTrain(foodtrain: foodtrain,
                       onSuccess: onSuccess,
                       onError: onError)
      }
    }
  }
  
  func joinTrain(foodtrain: Foodtrain,
    onSuccess: @escaping () -> (),
    onError: @escaping () -> () ) {
    foodtrain.join(withUsername: NSUserName(),
                   onSuccess: { foodtrain in 
                    let indexToReplace = self.foodtrains.index(of: foodtrain)
                    if let indexToReplace = indexToReplace {
                      self.foodtrains.replaceSubrange(indexToReplace...indexToReplace, with: [foodtrain])
                      self.sortFoodtrains()
                    }
                    onSuccess()
    }, onError: { error in
      onError()
    })
  }
  
  func unboardFoodTrain(withId id: Int,
                     onSuccess: @escaping () -> (),
                     onError: @escaping () -> () ) {
    foodtrains.forEach { (foodtrain) in
      if foodtrain.identifier == id {
        self.unboardTrain(foodtrain: foodtrain,
                       onSuccess: onSuccess,
                       onError: onError)
      }
    }
  }
  
  func unboardTrain(foodtrain: Foodtrain,
                 onSuccess: @escaping () -> (),
                 onError: @escaping () -> () ) {
    foodtrain.unboard(withUsername: NSUserName(),
                      onSuccess: { foodtrain in
                    let indexToReplace = self.foodtrains.index(of: foodtrain)
                    if let indexToReplace = indexToReplace {
                      self.foodtrains.replaceSubrange(indexToReplace...indexToReplace, with: [foodtrain])
                      self.sortFoodtrains()
                    }
                    onSuccess()
    }, onError: { error in
      onError()
    })
  }
  
  func isFoodtrainJoinable(foodtrain: Foodtrain) -> Bool {
    for foodtrainToCheck in self.foodtrains {
      if foodtrainToCheck.participants.contains(NSUserName()) {
        return false
      }
    }
    return true
  }
  
  func isFoodtrainUnboardable(foodtrain: Foodtrain) -> Bool {
    return foodtrain.participants.contains(NSUserName())
  }
  
  init() {
    self.schedulePollingtimer()
  }
  
  private func sortFoodtrains() {
    foodtrains = foodtrains.filter { (foodtrain) -> Bool in
      return foodtrain.participants.count > 0
    }
    
    foodtrains.sort { (foodtrainOne, foodtrainTwo) -> Bool in
      if(foodtrainOne.participants.contains(NSUserName())) {
        if(foodtrainTwo.participants.contains(NSUserName())) {
          return foodtrainOne.startTime < foodtrainTwo.startTime
        } else {
          return true
        }
      }
      if(foodtrainTwo.participants.contains(NSUserName())) {
        if(foodtrainOne.participants.contains(NSUserName())) {
          return foodtrainOne.startTime < foodtrainTwo.startTime
        } else {
          return false
        }
      }
      
      return foodtrainOne.startTime < foodtrainTwo.startTime
    }
  }
  
  func restartPollingIfNecessary() {
    if let pollingTimer = pollingTimer, !pollingTimer.isValid {
      self.schedulePollingtimer()
    } else if pollingTimer == nil {
      self.schedulePollingtimer()
    }
  }
  
  func schedulePollingtimer() {
    self.pollingTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.getFoodtrains), userInfo: nil, repeats: true)
    self.getFoodtrains()
  }
  
  @objc private func getFoodtrains() {
    
    Foodtrain.getFoodtrains(onSuccess: { (foodtrains) in
      
      var newParticipants: [String] = []
      var foodtrainWithNewParticipants: Foodtrain?
      
      var newFoodtrains: [Foodtrain] = []
      foodtrains.forEach({ (foodtrain) in
        if !self.foodtrains.contains(foodtrain) {
          newFoodtrains.append(foodtrain)
        } else {
          //compare pariticpants if you're a participant
          if(foodtrain.participants.contains(NSUserName())) {
            self.foodtrains.forEach({ (existingFoodtrain) in
              if existingFoodtrain.identifier == foodtrain.identifier {
                foodtrainWithNewParticipants = foodtrain
                foodtrain.participants.forEach({ (name) in
                  if !existingFoodtrain.participants.contains(name) {
                    newParticipants.append(name)
                  }
                })
              }
            })
          }
        }
      })
      
      if let foodtrainWithNewParticipants = foodtrainWithNewParticipants, newParticipants.count > 0 {
        let participantsString = newParticipants.joined(separator: ",")
        let message = "\(participantsString) joined your foodtrain leaving at \(foodtrainWithNewParticipants.shortTimeString())"
        let title = "Your foodtrain to \(foodtrainWithNewParticipants.restaurantName)"
        
        let notification = NSUserNotification.init()
        
        // set the title and the informative text
        notification.title = title
        notification.informativeText = message
        
        notification.soundName = NSUserNotificationDefaultSoundName
        
        notification.hasActionButton = false
        
        NSUserNotificationCenter.default.deliver(notification)
      }
      
      if(self.foodtrains.count > 0) {
        newFoodtrains.forEach({ (foodtrain) in
          // create a User Notification
          let notification = NSUserNotification.init()
          
          // set the title and the informative text
          notification.title = "Foodtrain to \(foodtrain.restaurantName) started"
          notification.informativeText = "\(foodtrain.creator) will leave at \(foodtrain.shortTimeString())"
          
          notification.userInfo = ["identifier" : foodtrain.identifier]
          
          // use the default sound for a notification
          notification.soundName = NSUserNotificationDefaultSoundName
          
          notification.hasActionButton = true
          notification.actionButtonTitle = "Join"
          
          // Deliver the notification through the User Notification Center
          NSUserNotificationCenter.default.deliver(notification)
        })
      }
      
      self.foodtrains = foodtrains
      self.sortFoodtrains()
      
      if let onFoodtrainUpdates = self.onFoodtrainUpdates {
        onFoodtrainUpdates()
      }
    }, onError: { error in
      dump(error)
    })
  }
  
}
