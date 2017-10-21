//
//  StationCollectionViewCell.swift
//  Volna
//
//  Created by Artem Malyshev on 1/14/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit

class StationCollectionViewCell: UICollectionViewCell {
  var stationUrl: String?
  private var placeholderImage: UIImage
  @IBOutlet weak var stationName: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  var radioStation: RadioStation!
  
  required init(coder aDecoder: NSCoder) {
    placeholderImage = UIImage(named: "placeholder.png")!
    placeholderImage = placeholderImage.resizeImage(newWidth: CGFloat(90))
    super.init(coder: aDecoder)!
//    self.layer.cornerRadius = 20
//    self.layer.masksToBounds = false
  }
  
  func prepareCellForDisplay(_ station: RadioStation) {
    imageView.image = placeholderImage
    isHidden = false
    radioStation = station
    stationName.text = parseName(station.name)
    stationName.layer.zPosition = 1
    backgroundColor = UIColor.white
    stationUrl = station.url
  
    setImage(station.image)
  }
  
  private func setImage(_ url: String) {
//    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      if let image = ImageCache.shared[url] {
//        DispatchQueue.main.async {
          imageView.image = image
        return
        }
//      }
  }
  
  private func parseName(_ name: String) -> String {
    if name.characters.count >= 17 {
      return name.replace(target: " ", withString: "\n")
    }
    return name
  }
}
