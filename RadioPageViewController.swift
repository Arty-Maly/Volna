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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = self
    delegate = self
    buttonDelegate = orderedViewControllers.last as? ButtonActionDelegate
    if let firstViewController = orderedViewControllers.first {
      setViewControllers([firstViewController],
                         direction: .forward,
                         animated: true,
                         completion: nil)
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool) {
    mainDelegate?.updateControl()
  }

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
      return nil
    }
    
    let previousIndex = viewControllerIndex - 1
    
    guard previousIndex >= 0 else {
      return nil
    }
    
    guard orderedViewControllers.count > previousIndex else {
      return nil
    }
    return orderedViewControllers[previousIndex]
  }
  
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
      return nil
    }
    
    let nextIndex = viewControllerIndex + 1
    let orderedViewControllersCount = orderedViewControllers.count
    
    guard orderedViewControllersCount != nextIndex else {
      return nil
    }
    
    guard orderedViewControllersCount > nextIndex else {
      return nil
    }
    return orderedViewControllers[nextIndex]
  }
  
  private(set) lazy var orderedViewControllers: [UIViewController] = {
    let radioStationControllers = [self.newRadioStationController(type: ViewControllerType.main),
                               self.newRadioStationController(type: ViewControllerType.favourite)]
    radioStationControllers.first?.stationCollectionDelegate = radioStationControllers.last
    radioStationControllers.last?.stationCollectionDelegate = radioStationControllers.first
    
    return radioStationControllers
  }()
  
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
}
