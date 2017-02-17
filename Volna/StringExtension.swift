//
//  StringExtension.swift
//  Volna
//
//  Created by Artem Malyshev on 2/17/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
extension String {
  func replace(target: String, withString replaceString: String) -> String {
    if let range = self.range(of: target) {
      return self.replacingCharacters(in: range, with: replaceString)
    }
    return self
  }
}
