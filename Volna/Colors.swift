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
  static let darkerBlueBorderColor = UIColor(red:0.24, green:0.40, blue:0.47, alpha:1.0)
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
  
  static func getUIntColor() -> UInt {
    var colorAsUInt : UInt32 = 0
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    if Colors.darkerBlue.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      colorAsUInt += UInt32(red * 255.0) << 16 +
        UInt32(green * 255.0) << 8 +
        UInt32(blue * 255.0)
    }
    
    return UInt(colorAsUInt)
  }
}

