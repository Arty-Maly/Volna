//
//  SearchBar.swift
//  Volna
//
//  Created by Artem Malyshev on 10/21/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit

class SearchBar: UISearchBar {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        if let imageView = textFieldInsideSearchBar?.leftView as? UIImageView {
            imageView.image = imageView.image?.transform(withNewColor: UIColor.white)
        }
        let button = textFieldInsideSearchBar?.value(forKey: "clearButton") as! UIButton
        if let image = button.imageView?.image {
            button.setImage(image.transform(withNewColor: UIColor.white), for: .normal)
        }
        
        textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(string: Constants.searchBarPlaceHolder, attributes: [NSForegroundColorAttributeName: UIColor.white])
        textFieldInsideSearchBar?.textColor = UIColor.white
    }
    
    func setupLayers() {
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }
}
