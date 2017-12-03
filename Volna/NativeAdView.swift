//
//  NativeAdView.swift
//  Volna
//
//  Created by Artem Malyshev on 12/9/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
import MoPub

@IBDesignable
class NativeAdView: UIView, MPNativeAdRendering {
    @IBOutlet weak var optOutIconHeight: NSLayoutConstraint!
    @IBOutlet weak var optOutIcon: UIImageView!
    @IBOutlet weak var callToActionButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var mainImageView: UIImageView!
    
    var view: UIView!
    var imageLoader: MPNativeAdRenderingImageLoader?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    private func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        optOutIconHeight.constant = Constants.adIconHeight
        iconImageView.layer.cornerRadius = 10
        callToActionButton.layer.cornerRadius = 3
        callToActionButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        callToActionButton.dropShadow()
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "NativeAdView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    func nativeMainTextLabel() -> UILabel {
        return self.mainTextLabel;
    }
    
    func nativeIconImageView() -> UIImageView! {
        return self.iconImageView
    }
    
//    func nativeMainImageView() -> UIImageView! {
//        return self.mainImageView
//    }
    
    func nativeTitleTextLabel() -> UILabel! {
        return self.titleLabel
    }
    
    func nativePrivacyInformationIconImageView() -> UIImageView! {
        return self.optOutIcon
    }
    
    func nativeCallToActionTextLabel() -> UILabel! {
        return callToActionButton.titleLabel
    }
    
    func layoutCustomAssets(withProperties customProperties: [AnyHashable : Any]!, imageLoader: MPNativeAdRenderingImageLoader!) {
        let iconImageUrl = customProperties[Constants.adIconImageUrl] as? String
        let optOutUrl = customProperties[Constants.adOptOutUrl] as? String
        let callToActionText = customProperties[Constants.adCallToActionText] as? String

        if let iconUrl = iconImageUrl {
            self.imageLoader?.loadImage(for: URL(string: iconUrl), into: iconImageView)
        }
        
        if let outUrl = optOutUrl {
            self.imageLoader?.loadImage(for: URL(string: outUrl), into: optOutIcon)
        }
        if let actionText = callToActionText {
            self.callToActionButton.setTitle(actionText, for: .normal)
        }
    }
}
