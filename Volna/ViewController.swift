import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
  private var player: RadioModel
  
  @IBOutlet weak var scrollView: UIScrollView!
  required init(coder aDecoder: NSCoder) {
    player = RadioModel()
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func playStation() {
    player.play()
    
    
  }
  
  @IBAction func setStation(_ sender: UIButton) {
    player.setStation(sender.currentTitle!)
  }
  
}

