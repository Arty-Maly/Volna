//
//  SplashViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
import CoreData

class SplashViewController: UIViewController {
  let imagePicker = UIImagePickerController()
  let convertQueue = DispatchQueue(label: "convertQueue", attributes: .concurrent)
  let saveQueue = DispatchQueue(label: "saveQueue", attributes: .concurrent)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self,
                                            selector: #selector(self.segueToMainView),
                                            name: NSNotification.Name(Constants.endOfSyncNotification),
                                            object: nil)
  }
  
  @objc private func segueToMainView() {
    DispatchQueue.main.async(){
      self.performSegue(withIdentifier: "transitionToRadio", sender:nil)
    }
  }
  override func viewDidAppear(_ animated: Bool) {
    getListOfRadioStations()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func parseResponse(data: Data) -> Array<Any>{
    let parsedData: Array<NSDictionary>
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Array<NSDictionary>]
      parsedData = json["stations"]!
    } catch {
      parsedData = []
      print("error parsing json")
    }
    return parsedData
  }

  private func getListOfRadioStations() {
    let dataHandler = DataHandler.shared
    dataHandler.syncRadioStations()
  }
}
