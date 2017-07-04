//
//  radioCollectionDelegate.swift
//
//
//  Created by Artem Malyshev on 7/4/17.
//
//

import Foundation
protocol StationCollectionDelegate: ButtonActionDelegate {
  func stationClicked(clickedStation: RadioStation)
}

