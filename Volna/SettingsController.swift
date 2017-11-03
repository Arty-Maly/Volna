//
//  SettingsController.swift
//  Volna
//
//  Created by Artem Malyshev on 10/25/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
class SettingsController: UITableViewController {
    private let defaults: UserDefaults
   
    @IBOutlet weak var favouriteSwitch: UISwitch!
    @IBAction func switchToFavourite(_ sender: Any) {
        if favouriteSwitch.isOn {
            defaults.setValue(true, forKey: Constants.startFromFavourites)
        } else {
            defaults.setValue(false, forKey: Constants.startFromFavourites)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellId = tableView.cellForRow(at: indexPath)?.reuseIdentifier else { return }
        
        switch cellId {
            case "reviewCell":
                if let url = URL(string: Constants.appLink),
                    UIApplication.shared.canOpenURL(url) {
                    Logger.logAcceptedReview()
                    UIApplication.shared.openURL(url)
                }
            default: break
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        defaults = UserDefaults.standard
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        if defaults.bool(forKey: Constants.startFromFavourites) {
            favouriteSwitch.setOn(true, animated: false)
        }
        super.viewDidLoad()
    }
}
