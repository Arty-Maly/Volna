//
//  topBar.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
class TopBar: BarView {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    setupLayers()
  }
  
  private func setupLayers() {
    self.layer.addBorder(edge: UIRectEdge.bottom, color: Colors.borderColor, thickness: 1)
    let gradient = Colors.topGradient()
    gradient.frame = self.bounds
    self.layer.insertSublayer(gradient, at: UInt32(0))
  }
}
