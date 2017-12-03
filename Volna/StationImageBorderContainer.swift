//
//  playButtonBorderContainer.swift
//  Volna
//
//  Created by Artem Malyshev on 12/3/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit
class stationImageBorderContainer: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        self.layer.frame = self.bounds
        super.layoutSubviews()
    }
}
