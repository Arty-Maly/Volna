//
//  InfoAlert.swift
//  Volna
//
//  Created by Artem Malyshev on 9/1/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit


class InfoAlert: BaseAlert {
  
  override init(alertWidth: CGFloat) {
  	super.init(alertWidth: alertWidth)
    addButtons()
  }

  func showAlert() {
    let colorAsUInt = Colors.getUIntColor()
  	alertView.showInfo(Constants.capabilitiesTitle,
  	                   subTitle: Constants.capabilitiesText,
  	                   colorStyle: UInt(colorAsUInt),
  	                   circleIconImage: UIImage(named: "lightbulb"))
  }
  
  private func addButtons() {
  	alertView.addButton("ОК", backgroundColor: Colors.darkerBlue, textColor: UIColor.white, showDurationStatus: true) {}
  }
}


