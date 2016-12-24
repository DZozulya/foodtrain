//
//  Foodtrain.swift
//  FoodTrain
//
//  Created by Leon Stellbrink on 11/10/16.
//  Copyright © 2016 FoodTrain All rights reserved.
//

import Foundation
import Alamofire

class Foodtrain: Hashable {
  
  let identifier: Int
  let creator: String
  let restaurantName: String
  let startTime: Date
  let yelpId: String
  let participants: [String]
  
  fileprivate static func hostForRequests() -> String {
    return Bundle.main.object(forInfoDictionaryKey: "FT_HOST") as! String
  }
  
  func userJoined() -> Bool {
    return participants.contains(NSUserName())
  }
  
  static func getFoodtrains(onSuccess: @escaping ([Foodtrain]) -> (), onError: @escaping (Error) -> ()) {
    Alamofire.request(Foodtrain.hostForRequests() + "trains/").validate().responseJSON { response in
      switch response.result {
      case .success:
        if let JSON = response.result.value as? [[String: AnyObject]] {
          onSuccess(JSON.map({Foodtrain.makeFoodtrainFromJson(json: $0)}))
        }
      case .failure(let error):
        onError(error)
      }
    }
  }
  
  static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return dateFormatter
  }()
  
  static func createFoodtrain(creator: String,
                              restaurantName: String,
                              yelpId: String,
                              startTime: Date,
                              onSuccess: @escaping (Foodtrain) -> (),
                              onError: @escaping (Error) -> ()) {
    let startDateString = Foodtrain.dateFormatter.string(from: startTime)
    let params: [String: Any] = ["creator": creator, "restaurant_name": restaurantName, "start_time": startDateString, "yelp_id": yelpId]
    
    Alamofire.request(Foodtrain.hostForRequests() + "trains/",
                      method: .post,
                      parameters: params,
                      encoding: JSONEncoding.default).validate().responseJSON { response in
                        switch response.result {
                        case .success:
                          if let JSON = response.result.value as? [String: AnyObject] {
                            onSuccess(Foodtrain.makeFoodtrainFromJson(json: JSON))
                          }
                        case .failure(let error):
                          onError(error)
                        }
    }
  }
  
  func join(withUsername username:String,
            onSuccess: @escaping (Foodtrain) -> (),
            onError: @escaping (Error) -> ()) {
    let params: [String: Any] = ["name": username]
    Alamofire.request(Foodtrain.hostForRequests() + "train/\(identifier)/join/",
      method: .post,
      parameters: params,
      encoding: JSONEncoding.default).responseJSON { response in
        switch response.result {
        case .success:
          if let JSON = response.result.value as? [String: AnyObject] {
            onSuccess(Foodtrain.makeFoodtrainFromJson(json: JSON))
          }
        case .failure(let error):
          onError(error)
        }
    }
  }
  
  func unboard(withUsername username:String,
               onSuccess: @escaping (Foodtrain) -> (),
               onError: @escaping (Error) -> ()) {
    let params: [String: Any] = ["name": username]
    Alamofire.request(Foodtrain.hostForRequests() + "train/\(identifier)/leave/",
                      method: .post,
                      parameters: params,
                      encoding: JSONEncoding.default).validate().responseJSON { (response) in
                        switch response.result {
                        case .success:
                          if let JSON = response.result.value as? [String: AnyObject] {
                            onSuccess(Foodtrain.makeFoodtrainFromJson(json: JSON))
                          }
                        case .failure(let error):
                          onError(error)
                        }
    }
  }
  
  
  static func makeFoodtrainFromJson(json: [String: AnyObject]) -> Foodtrain {
    let identifier = json["id"] as! Int
    let creator = json["creator"] as! String
    let restaurantName = json["restaurant_name"] as! String
    let startTimeString = json["start_time"] as! String
    let startTime = Foodtrain.dateFormatter.date(from: startTimeString)!
    let yelpId = json["yelp_id"] as! String
    let participants = json["participants"] as! [String]
    
    let foodtrain = Foodtrain(identifier: identifier,
                              creator: creator,
                              restaurantName: restaurantName,
                              startTime: startTime,
                              yelpId: yelpId,
                              participants: participants)
    return foodtrain
  }
  
  init(identifier: Int, creator: String, restaurantName:String, startTime: Date, yelpId: String,  participants: [String]) {
    self.identifier = identifier
    self.creator = creator
    self.restaurantName = restaurantName
    self.startTime = startTime
    self.yelpId = yelpId
    self.participants = participants
  }
  
  public static func ==(lhs: Foodtrain, rhs: Foodtrain) -> Bool {
    return lhs.identifier == rhs.identifier
  }
  
  public var hashValue: Int { get{
    return identifier
    }
  }
  
  static let shortTimeDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    return dateFormatter
  }()
  
  func shortTimeString() -> String {
    return Foodtrain.shortTimeDateFormatter.string(from: startTime)
  }
  
  func descriptionString() -> String {
    if participants.count == 1 {
      return "by \(creator), \(participants.count) passenger"
    } else {
      return "by \(creator), \(participants.count) passengers"
    }
  }
  
}
