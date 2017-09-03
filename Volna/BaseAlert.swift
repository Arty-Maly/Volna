//
//  BaseAlert.swift
//  Volna
//
//  Created by Artem Malyshev on 9/2/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import SCLAlertView

class BaseAlert {
  let appearance: SCLAlertView.SCLAppearance
  let alertView: SCLAlertView
  
  init(alertWidth: CGFloat) {
  	appearance = SCLAlertView.SCLAppearance(kCircleHeight: CGFloat(80),
                                            	kCircleIconHeight: CGFloat(55),
                                            	kTitleTop: CGFloat(40),
                                            	kWindowWidth: alertWidth,
                                              kTitleFont: UIFont(name: "HelveticaNeue", size: 22)!,
                                              kTextFont: UIFont(name: "HelveticaNeue", size: 17)!,
                                              kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 17)!,
                                              showCloseButton: false,
                                              contentViewColor: Colors.lighterBlue,
                                              contentViewBorderColor: Colors.lighterBlue,
                                              titleColor: UIColor.white)
  	alertView = SCLAlertView(appearance: appearance)
  }
  
}
