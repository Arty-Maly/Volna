//
//  bottomBar.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
@IBDesignable
class BarView: UIView {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
    self.layer.masksToBounds = true
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
}
