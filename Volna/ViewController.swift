import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
  private var player: RadioModel
  @IBOutlet weak var stationTitle: UILabel!
  
  required init(coder aDecoder: NSCoder) {
    player = RadioModel()
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print(error)
    }
  }
  
  @IBAction func playStation() {
    player.play()
  }
  
  @IBAction func setStation(_ sender: UIButton) {
    player.setStation(sender.currentTitle!)
    stationTitle.text = sender.currentTitle!
  }
  
}

