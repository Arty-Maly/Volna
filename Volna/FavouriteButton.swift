//
//  FavouriteButton.swift
//  Volna
//
//  Created by Artem Malyshev on 7/3/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit
@IBDesignable
class FavouriteButton: UIButton {
  private var hearts: [ButtonState:UIImage]?
  private(set) var displayedState: ButtonState
  
  required init(coder aDecoder: NSCoder) {
    displayedState = .inactive
    super.init(coder: aDecoder)!
    self.layer.masksToBounds = true
  }
  
  override init(frame: CGRect) {
    displayedState = .inactive
    super.init(frame: frame)
  }
  
  override func layoutSubviews() {
    initImages()
    self.setImage(hearts![displayedState], for: .normal)
    super.layoutSubviews()
  }
  
  private func initImages() {
    let bundle = Bundle(for: self.classForCoder)
    hearts = [.inactive : UIImage(named: "heart-empty.png", in: bundle, compatibleWith: self.traitCollection)!,
              .active : UIImage(named: "heart-fav.png", in: bundle, compatibleWith: self.traitCollection)!]
  }
  
  func switchImage() {
    
    displayedState.toggleState()
    self.setImage(hearts![displayedState], for: .normal)
  }
}
