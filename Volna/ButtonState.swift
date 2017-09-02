//
//  ButtonState.swift
//  Volna
//
//  Created by Artem Malyshev on 7/3/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

enum ButtonState {
  case active
  case inactive
  mutating func toggleState() {
    switch self {
    case .active: self = .inactive
    case .inactive: self = .active
    }
  }
}
  
