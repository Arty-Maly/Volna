//
//  uiImageExtension.swift
//  Volna
//
//  Created by Artem Malyshev on 1/29/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

  func resizeImage(newWidth: CGFloat) -> UIImage {
    let scale = newWidth / self.size.width
    let newHeight = self.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  

}
