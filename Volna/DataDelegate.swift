//
//  DataDelegate.swift
//  Volna
//
//  Created by Artem Malyshev on 10/11/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import Foundation

protocol DataDelegate {
    
    func matchLocalData(with data: Data)
    func error()
}
