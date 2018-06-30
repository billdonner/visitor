//
//  ViewController.swift
//  visitor
//
//  Created by bill donner on 6/27/18.
//  Copyright © 2018 bill donner. All rights reserved.
//

import UIKit
import CoreLocation

struct Cfg {
   static let pingcycle = 10.0
   static  let cyclesbeforeaskingagain = 4
   static  let tenMeters = 10.0
   static  let deferUntilTraveled = 10.0
   static  let deferTimeout = 15.0
static let locationTechnique:LocationTechnique = .visitEvent
}
class ModeTestViewController: UIViewController {
   
    var locMinder:LocMinder!
    var gameTimer: Timer!
    var cyclesbeforeswitch = Cfg.cyclesbeforeaskingagain
    var mode:LocationTechnique = Cfg.locationTechnique
    var cyclenum = 0
    @IBOutlet weak var testInfo: UILabel!
    @IBOutlet weak var serverChatInfo: UILabel!
    @IBOutlet weak var iosSensorInfo: UILabel!
    
    @objc func pollCycle () {
        
        cyclenum += 1
        
        let llc = LastKnownLocation.fetchfromUserDefaults()
        if let llc = llc  {
            self.serverChatInfo.text = "\(mode) ping# \(self.cyclenum)\n\(llc.description())"
           // print(self.topLabel.text ?? "fubar")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameTimer = Timer.scheduledTimer(timeInterval: Cfg.pingcycle, target: self, selector: #selector(pollCycle), userInfo: nil, repeats: true)
        pollCycle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Override point for customization after application launch.
        // if not simulator, open console pipe
        self.serverChatInfo.text = "warming up ..."
        self.testInfo.text = "\(mode) ping every \(Cfg.pingcycle) secs"
        locMinder = LocMinder(mode){ str in
            // com here when something interesting to show
            self.iosSensorInfo.text = str
            self.iosSensorInfo.setNeedsLayout()
            self.cyclesbeforeswitch -= 1
            if self.cyclesbeforeswitch == 0 {
            self.locMinder.startAlways(self)
            }
        }
        // always start with wheninuse, will ask for alwyas in a little while
        locMinder.startWhenInUse(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

