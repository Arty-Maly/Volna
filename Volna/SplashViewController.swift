//
//  SplashViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit
import CoreData

class SplashViewController: UIViewController, ErrorDelegate {
    
    var connectionAlert: ConnectionAlert?
    var dataHandler: DataHandler?
    
    let semaphore = DispatchSemaphore(value: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetState()
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
    
    func recievedError() {
        semaphore.wait()
        guard connectionAlert == nil else { return }
        DispatchQueue.main.async() {
            self.dataHandler = nil
            self.connectionAlert = ConnectionAlert(self)
            self.connectionAlert?.showAlert()
            self.semaphore.signal()
        }
    }
    
    private func getListOfRadioStations() {
        dataHandler = DataHandler(dataHandlerDelegate: self)
        dataHandler?.syncRadioStations()
    }
    
    private func resetState() {
        dataHandler = nil
        connectionAlert = nil
    }
}
