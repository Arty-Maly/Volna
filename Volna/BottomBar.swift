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
  }
  
  func setupLayers() {
    let gradient = Colors.bottomGradient()
    gradient.frame = self.bounds
    self.layer.insertSublayer(gradient, at: UInt32(0))
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    setupLayers()
  }
}
