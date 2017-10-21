//
//  File.swift
//  Volna
//
//  Created by Artem Malyshev on 10/6/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit

class ConnectionAlert: BaseAlert {
    var controller: SplashViewController?
    override init(alertWidth: CGFloat) {
        super.init(alertWidth: alertWidth)
        addButton()
    }
    convenience init(_ controller: SplashViewController) {
        self.init(alertWidth: 300.0)
        self.controller = controller
    }
    
    func showAlert() {
        let colorAsUInt = Colors.getUIntColor()
        alertView.showInfo(Constants.noConnectionTitle,
                           subTitle: Constants.noConnectionBody,
                           colorStyle: UInt(colorAsUInt),
                           circleIconImage: UIImage(named: "warning"))
    }
    
    private func addButton() {
        alertView.addButton(Constants.retryApp,
                            backgroundColor: Colors.darkerBlue,
                            textColor: UIColor.white,
                            showDurationStatus: true) { _ in
                                self.controller?.viewDidLoad()
                                self.controller?.viewDidAppear(false)
                                
        }
    }
}


