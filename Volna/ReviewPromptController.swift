//
//  ReviewPromptController.swift
//  
//
//  Created by Artem Malyshev on 7/8/17.
//
//

import UIKit

class ReviewPromptController: BaseAlert {
    
    override init(alertWidth: CGFloat) {
        super.init(alertWidth: alertWidth)
        addButtons()
    }
    
    func showAlert() {
        let colorAsUInt = Colors.getUIntColor()
        alertView.showInfo("",
                           subTitle: Constants.reviewMessage,
                           colorStyle: UInt(colorAsUInt),
                           circleIconImage: UIImage(named: "pencil"))
    }
    
    private func addButtons() {
        alertView.addButton(Constants.agreeToReview, backgroundColor: Colors.darkerBlue, textColor: UIColor.white, showDurationStatus: true)  { _ in
            User.setAskForReviewToFalse()
            if let url = URL(string: Constants.appLink),
                UIApplication.shared.canOpenURL(url) {
                Logger.logAcceptedReview()
                UIApplication.shared.openURL(url)
            }
        }
        
        alertView.addButton(Constants.askLater, backgroundColor: Colors.darkerBlue, textColor: UIColor.white, showDurationStatus: true)  { _ in
            Logger.logRequestLater()
        }
        
        alertView.addButton(Constants.doNotAskAgain, backgroundColor: Colors.darkerBlue, textColor: UIColor.white, showDurationStatus: true)  { _ in
            User.setAskForReviewToFalse()
            Logger.logRequestNever()
        }
        
    }
}

