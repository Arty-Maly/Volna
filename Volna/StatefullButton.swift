////
////  FavouriteButton.swift
////  Volna
////
////  Created by Artem Malyshev on 7/3/17.
////  Copyright © 2017 Artem Malyshev. All rights reserved.
////
//import UIKit
//@IBDesignable
//class StatefullButton: UIButton {
//  var buttonImages: [ButtonState:UIImage]?
//  var displayedState: ButtonState
//  
//  required init(coder aDecoder: NSCoder) {
//    displayedState = .inactive
//    super.init(coder: aDecoder)!
//    self.layer.masksToBounds = true
//  }
//  
//  override init(frame: CGRect) {
//    displayedState = .inactive
//    super.init(frame: frame)
//  }
//  
//  override func layoutSubviews() {
//    initImages()
//    self.setImage(buttonImages?[displayedState], for: .normal)
//    super.layoutSubviews()
//  }
//  
//  private func initImages() {
//  }
//  
//  func switchImage() {
//    self.setImage(buttonImages?[displayedState], for: .normal)
//    displayedState.toggleState()
//  }
//}
