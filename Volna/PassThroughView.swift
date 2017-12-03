//
//  PassThroughView.swift
//  Volna
//
//  Created by Artem Malyshev on 12/5/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
class PassThroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
