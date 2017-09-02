//
//  InfoAlert.swift
//  Volna
//
//  Created by Artem Malyshev on 9/1/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
//import JSSAlertView

class InfoAlert {
  let alertController:  UIAlertController
  private let oneAction: UIAlertAction
  private let twoAction: UIAlertAction
  private let cancelAction: UIAlertAction
  
  init() {
    alertController = UIAlertController(title: Constants.reviewTitle, message: Constants.reviewMessage, preferredStyle: .alert)
    oneAction = UIAlertAction(title: Constants.agreeToReview, style: .default) { _ in
      User.setAskForReviewToFalse()
      if let url = URL(string: Constants.appLink),
        UIApplication.shared.canOpenURL(url) {
        Logger.logAcceptedReview()
        UIApplication.shared.openURL(url)
      }
    }
    twoAction = UIAlertAction(title: Constants.askLater, style: .default) { _ in
      Logger.logRequestLater()
    }
    cancelAction = UIAlertAction(title: Constants.doNotAskAgain, style: .cancel) { _ in
      User.setAskForReviewToFalse()
      Logger.logRequestNever()
    }
    
    alertController.addAction(oneAction)
    alertController.addAction(twoAction)
    alertController.addAction(cancelAction)
  }
}


