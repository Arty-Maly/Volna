//
//  bottomBar.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
@IBDesignable
class MetadataContainer: PassThroughView {
    func setupLayers() {
        self.layer.needsDisplayOnBoundsChange = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }
}

