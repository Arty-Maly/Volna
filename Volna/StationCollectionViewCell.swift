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
  
  required init(coder aDecoder: NSCoder) {
    placeholderImage = UIImage(named: "placeholder.png")!
    placeholderImage = placeholderImage.resizeImage(newWidth: CGFloat(90))
    super.init(coder: aDecoder)!
  }
  
  func prepareCellForDisplay(_ station: RadioStation) {
    self.imageView.image = placeholderImage
    self.stationName.text = station.name
    self.stationName.layer.zPosition = 1
    self.backgroundColor = UIColor.white
    self.stationUrl = station.url
    let url = URL(string: station.image!)!
    setImage(url)
  }
  
  
  private func setImage(_ url: URL) {
    DispatchQueue.global(qos: .userInitiated).async {
      let data = try? Data(contentsOf: url)
      let image = UIImage(data: data!)!
      DispatchQueue.main.async { [weak self] in
        self?.imageView.image = image.resizeImage(newWidth: CGFloat(90))
      }
    }
  }
}
