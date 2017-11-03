//
//  UIVIewControllerExtension.swift
//  Volna
//
//  Created by Artem Malyshev on 10/22/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
