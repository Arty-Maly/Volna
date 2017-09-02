//
//  UIViewExtension.swift
//  Volna
//
//  Created by Artem Malyshev on 8/20/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit

extension UIView {
  
  func dropShadow() {
    
    self.layer.masksToBounds = false
    self.layer.shadowColor = UIColor.black.cgColor
    self.layer.shadowOpacity = 0.0
//    self.layer.shadowOffset = CGSize(width: -1, height: 1)
    self.layer.shadowRadius = 1
    
    self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    self.layer.shouldRasterize = true
    
    self.layer.rasterizationScale = UIScreen.main.scale
    
  }
}
