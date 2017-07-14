//
//  ReviewPromptController.swift
//  
//
//  Created by Artem Malyshev on 7/8/17.
//
//

import UIKit

class ReviewPromptController {
  let alertController:  UIAlertController
  private let oneAction: UIAlertAction
  private let twoAction: UIAlertAction
  private let cancelAction: UIAlertAction
  
  init() {
    alertController = UIAlertController(title: Constants.reviewTitle, message: Constants.reviewMessage, preferredStyle: .alert)
    oneAction = UIAlertAction(title: Constants.agreeToReview, style: .default) { _ in
      User.setAskForReviewToFalse()
      if let url = URL(string: Constants.appLink),
      UIApplication.shared.canOpenURL(url){
      UIApplication.shared.openURL(url)
      }}
    twoAction = UIAlertAction(title: Constants.askLater, style: .default) { _ in }
    cancelAction = UIAlertAction(title: Constants.doNotAskAgain, style: .cancel) { _ in User.setAskForReviewToFalse() }
    
    alertController.addAction(oneAction)
    alertController.addAction(twoAction)
    alertController.addAction(cancelAction)
  }
}

