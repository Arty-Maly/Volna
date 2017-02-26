//
//  colors.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit

struct Colors {
  static let borderColor = UIColor(red:0.31, green:0.52, blue:0.61, alpha:1.0)
  static let darkerBlue = UIColor(red:0.27, green:0.45, blue:0.53, alpha:1.0)
  static let lighterBlue = UIColor(red:0.38, green:0.65, blue:0.76, alpha:1.0)
  static let highlightColor = UIColor(red:0.84, green:0.86, blue:0.88, alpha:0.85)
  
  static func bottomGradient() -> CAGradientLayer {
    return gradient(lighterBlue, darkerBlue)
  }
  
  static func topGradient() -> CAGradientLayer {
    return gradient(darkerBlue, lighterBlue)
  }
  
  private static func gradient(_ top_color: UIColor, _ bottom_color: UIColor) -> CAGradientLayer {
    let gl = CAGradientLayer()
    gl.colors = [top_color.cgColor, bottom_color.cgColor]
    gl.locations = [0.0, 1.0]
    
    return gl
  }
}

