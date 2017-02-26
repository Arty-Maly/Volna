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
  
  required init(url: URL) {
    self.url = url
  }
  
  
  func getStations(completion: @escaping (_ data: Data) -> ()) {
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
      if let json = data {
        completion(json)
      }
    }
    task.resume()
    
  }
}
