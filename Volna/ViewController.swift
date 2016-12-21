import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
  private var player: RadioModel
  @IBOutlet weak var stationTitle: UILabel!
  @IBOutlet weak var playButton: UIButton!
  
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
    togglePlaybackButton()
    player.play()
  }
  
  @IBAction func setStation(_ sender: UIButton) {
    togglePlaybackButton()
    player.setStation(sender.currentTitle!)
    stationTitle.text = sender.currentTitle!
  }
  
  private func togglePlaybackButton() {
    if player.isPaused() {
      if let image = UIImage(named: "pause_button.png") {
        playButton.setImage(image, for: .normal)
      }
    } else {
      if let image = UIImage(named: "play_button.png") {
        playButton.setImage(image, for: .normal)
      }
    }
  }
}

