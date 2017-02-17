//
//  bottomBar.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
class BottomBar: BarView {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
//    self.layer.borderWidth = 1
//    
//    self.layer.borderColor = UIColor(red:0.31, green:0.52, blue:0.61, alpha:1.0).cgColor
//    self.layer.masksToBounds = true
    self.layer.addBorder(edge: UIRectEdge.top, color: Colors.borderColor, thickness: 1)
    print(Colors.bottomGradient())
    let gradient = Colors.bottomGradient()
    gradient.frame = self.bounds
    self.layer.insertSublayer(gradient, at: UInt32(0))
  
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
}
