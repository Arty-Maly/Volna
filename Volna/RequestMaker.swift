//
//  RequestGenerator.swift
//  Volna
//
//  Created by Artem Malyshev on 2/18/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation

class RequestMaker {
    private let url: URL
    let dataDelegate: DataDelegate
    
    required init(url: URL, dataDelegate: DataDelegate) {
        self.url = url
        self.dataDelegate = dataDelegate
    }
    
    
    func getStations() {
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if let json = data {
                self.dataDelegate.matchLocalData(with: json)
            } else {
                self.dataDelegate.error()
            }
        }
        task.resume()
        
    }
}
