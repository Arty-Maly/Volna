class RepeatingTimer {
    private var deadline: Int
    private var interval: DispatchTimeInterval!
    
    
    init(deadline: Int, interval: Int) {
        self.deadline = deadline
        self.interval = .seconds(interval)
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        let d = self.deadline
        t.scheduleRepeating(deadline: .now() + .seconds(d), interval: self.interval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
