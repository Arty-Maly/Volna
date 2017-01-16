//
//  SplashViewController.swift
//  Volna
//
//  Created by Artem Malyshev on 1/16/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
//    performSegue(withIdentifier: "transitionToRadio", sender:self)
    let url = NSURL(string: "a")
    
    let task = URLSession.shared.dataTask(with: url! as URL) {[weak self] (data, response, error) in
      self?.parseResponse(data: data!)
      DispatchQueue.main.async(){
        self?.performSegue(withIdentifier: "transitionToRadio", sender:nil)
      }
//      print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "default")
    }
    
    task.resume()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func parseResponse(data: Data){
    do {
      let parsedData = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Array<NSDictionary>]
//      for (key,value) in parsedData["stations"]! {
        print(parsedData["stations"]?[0] ?? "bla")
//      }
    } catch {
      print("error parsing json")
    }
  }
}
