//
//  uiImageExtension.swift
//  Volna
//
//  Created by Artem Malyshev on 1/29/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit

extension UIImage {

  func resizeImage(newWidth: CGFloat) -> UIImage {
    let scale = newWidth / self.size.width
    let newHeight = self.size.height * scale
    UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 0)
    self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
  }
  
  
  func imageWithInsets(insets: UIEdgeInsets) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(
      CGSize(width: self.size.width + insets.left + insets.right,
             height: self.size.height + insets.top + insets.bottom), false, 0)
    let _ = UIGraphicsGetCurrentContext()
    let origin = CGPoint(x: insets.left, y: insets.top)
    self.draw(at: origin)
    let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return imageWithInsets!
  }
  
  func toSquare() -> UIImage {
    let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
    view.image = self
    view.contentMode = .scaleAspectFit
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
    view.layer.render(in: UIGraphicsGetCurrentContext()!)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }

}
