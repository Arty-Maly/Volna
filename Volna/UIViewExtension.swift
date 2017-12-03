//
//  UIViewExtension.swift
//  Volna
//
//  Created by Artem Malyshev on 8/20/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    //done so I can add and experiment with border thickness in Storyboard
//    @IBInspectable var borderTop: CGFloat {
//        get {
//            return 0
//        }
//
//        set {
//            addBorder(edge: .top, color: Colors.darkerBlueBorderColor, thickness: newValue)
//        }
//    }
//
//    @IBInspectable var borderBottom: CGFloat {
//        get {
//            return 0
//        }
//
//        set {
//            addBorder(edge: .bottom, color: Colors.darkerBlueBorderColor, thickness: newValue)
//
//        }
//    }
    
    @IBInspectable var shadowColor: UIColor? {
        set {
            layer.shadowColor = newValue!.cgColor
        }
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            else {
                return nil
            }
        }
    }
    
    /* The opacity of the shadow. Defaults to 0. Specifying a value outside the
     * [0,1] range will give undefined results. Animatable. */
    @IBInspectable var shadowOpacity: Float {
        set {
            layer.shadowOpacity = newValue
        }
        get {
            return layer.shadowOpacity
        }
    }
    
    /* The shadow offset. Defaults to (0, -3). Animatable. */
    @IBInspectable var shadowOffset: CGPoint {
        set {
            layer.shadowOffset = CGSize(width: newValue.x, height: newValue.y)
        }
        get {
            return CGPoint(x: layer.shadowOffset.width, y:layer.shadowOffset.height)
        }
    }
    
    /* The blur radius used to create the shadow. Defaults to 3. Animatable. */
    @IBInspectable var shadowRadius: CGFloat {
        set {
            layer.shadowRadius = newValue
        }
        get {
            return layer.shadowRadius
        }
    }
    
    
    func addBorder(edge: UIRectEdge, color: UIColor?, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect(x: 0, y: self.frame.height - thickness, width: self.frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: self.frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect(x: self.frame.width - thickness, y: 0, width: thickness, height: self.frame.height)
            break
        default:
            break
        }
        border.needsDisplayOnBoundsChange = true
        border.backgroundColor = color?.cgColor;
        self.layer.addSublayer(border)
    }
    
    func dropShadow() {
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: -4.0, height: 0.0)
        self.layer.shadowRadius = 1
        self.layer.cornerRadius = 3
        
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        
        self.layer.rasterizationScale = UIScreen.main.scale
        
    }
    func slideInFromRight(duration: TimeInterval = 0.35, completionDelegate: AnyObject? = nil) {
        slideIn(from: .right, duration: duration, completionDelegate:  completionDelegate)
    }
    
    func slideInFromLeft(duration: TimeInterval = 0.35, completionDelegate: AnyObject? = nil) {
        slideIn(from: .left, duration: duration, completionDelegate:  completionDelegate)
    }
    
    private func slideIn(from direction: Direction, duration: TimeInterval, completionDelegate: AnyObject?) {
        let slideTransition = CATransition()
        
        if let delegate: AnyObject = completionDelegate {
            slideTransition.delegate = delegate as? CAAnimationDelegate
        }
        slideTransition.type = kCATransitionPush
        if direction == .left {
            slideTransition.subtype = kCATransitionFromLeft
        } else {
            slideTransition.subtype = kCATransitionFromRight
        }
        slideTransition.duration = duration
        slideTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideTransition.fillMode = kCAFillModeRemoved
        self.layer.add(slideTransition, forKey: "slideInTransition")
    }
    
}
