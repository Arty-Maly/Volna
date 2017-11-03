//
//  PageViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 6/28/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import CoreData
import GoogleMobileAds

import Foundation
class RadioPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, StationViewDelegate, ButtonActionDelegate {
    
    weak var mainDelegate: MainViewPageControlDelegate?
    weak var buttonDelegate: ButtonActionDelegate?
    private var mainStationController: StationsViewController?
    private var favouriteStationController: StationsViewController?
    private var settingsController: SettingsController?
    private let initialIndex: Int
    private let defaults: UserDefaults
    
    required init(coder aDecoder: NSCoder) {
        defaults = UserDefaults.standard
        if defaults.bool(forKey: Constants.startFromFavourites) {
            initialIndex = 2
        } else {
            initialIndex = 1
        }
        
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        initControllers()
        buttonDelegate = favouriteStationController
        setViewControllers()        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        mainDelegate?.updateControl(initialIndex)
    }
    
    private func setViewControllers() {
        if defaults.bool(forKey: Constants.startFromFavourites) {
            guard let favouriteStationController = favouriteStationController else { return }
            setViewControllers([favouriteStationController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
            warmUpMainStationController()
            
        } else {
            guard let mainController = mainStationController else { return }
            setViewControllers([mainController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }
    
    private func warmUpMainStationController() {
        mainStationController?.viewDidLoad()
        mainStationController?.stationCollection?.setNeedsLayout()
        mainStationController?.stationCollection?.layoutIfNeeded()
    }
    
    private func initControllers() {
        mainStationController = newRadioStationController(type: ViewControllerType.main)
        favouriteStationController = newRadioStationController(type: ViewControllerType.favourite)
        settingsController = newSettingsController()
        mainStationController?.stationCollectionDelegate = favouriteStationController
        favouriteStationController?.stationCollectionDelegate = mainStationController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed else { return }
        guard let viewController = pageViewController.viewControllers?[0] else { return }
        
        if viewController == mainStationController {
            mainDelegate?.updateControl(1)
        }
        if viewController == favouriteStationController {
            mainDelegate?.updateControl(2)
        }
        if viewController == settingsController {
            mainDelegate?.updateControl(0)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard viewController != settingsController else { return nil }
        guard viewController != favouriteStationController else { return mainStationController }
        
        return settingsController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard viewController != favouriteStationController else { return nil }
        guard viewController != settingsController else { return mainStationController }
        
        return favouriteStationController
    }
    
    private func newSettingsController() -> SettingsController {
        let settingsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Constants.settingsControllerId) as! UITableViewController
        
        return settingsController as! SettingsController
    }
    
    private func newRadioStationController(type: ViewControllerType) -> StationsViewController {
        let radioStationConroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Constants.stationViewControllerId) as! StationsViewController
        radioStationConroller.stationViewDelegate = self
        radioStationConroller.type = type
        return radioStationConroller
    }
    
    func change(station: RadioStation) {
        mainDelegate?.change(station: station)
    }
    func favouriteButtonPressed() {
        buttonDelegate?.favouriteButtonPressed()
    }
    func updateCurrentStation(station: RadioStation) {
        mainStationController?.stationClicked(clickedStation: station)
        favouriteStationController?.stationClicked(clickedStation: station)
    }
}
