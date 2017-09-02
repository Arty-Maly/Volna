//
//  Logger.swift
//  Volna
//
//  Created by Artem Malyshev on 8/13/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import FirebaseAnalytics

class Logger {
  
  class func logReviewPresented(numberOfTimes: Int32) {
    Analytics.logEvent("review_presented", parameters: [
      "name": "Review Presented" as NSObject,
      "full_text": "Review Presented and the app was opened \(numberOfTimes) times" as NSObject
      ])
  }
  
  class func logAcceptedReview() {
    Analytics.logEvent("review_accepted", parameters: [
      "name": "Review Accepted" as NSObject,
      "full_text": "Review request accepted and user sent to app store" as NSObject
      ])
  }
  
  class func logRequestLater() {
    Analytics.logEvent("review_later", parameters: [
      "name": "Review Later" as NSObject,
      "full_text": "User pressed review later" as NSObject
      ])
  }
  
  
  class func logRequestNever() {
    Analytics.logEvent("review_never", parameters: [
      "name": "Review Never" as NSObject,
      "full_text": "User requested to never review app" as NSObject
      ])
  }
}