//
//  ViewController.swift
//  visitor
//
//  Created by bill donner on 6/27/18.
//  Copyright © 2018 bill donner. All rights reserved.
//

import UIKit
import CoreLocation
    let pingcycle = 10.0
    let cyclesbeforeaskingagain = 4
let deferUntilTraveled = 10.0
let deferTimeout = 15.0


class ViewController: UIViewController {
    var locMinder:LocMinder!
    var gameTimer: Timer!
    var counter = cyclesbeforeaskingagain
    var mode:LocationTechnique = .deferredUpdate

    var cyclenum = 0
    
    
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @objc func pollCycle () {
        
        cyclenum += 1
        
        let llc = LastKnownLocation.fetchfromUserDefaults()
        if let llc = llc  {
            self.topLabel.text = "\(mode) ping# \(self.cyclenum) \(llc.description()) secs:\(pingcycle)"
            print(self.topLabel.text ?? "fubar")
        }
        else {
            self.topLabel.text = "\(self.counter) warming..."
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameTimer = Timer.scheduledTimer(timeInterval: pingcycle, target: self, selector: #selector(pollCycle), userInfo: nil, repeats: true)
        pollCycle()
        
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Override point for customization after application launch.
        // if not simulator, open console pipe
        self.middleLabel.text = "\(mode) ping every \(pingcycle) secs"
        locMinder = LocMinder(mode){ str in
            // com here when something interesting to show
            self.bottomLabel.text = str
            self.bottomLabel.setNeedsLayout()
            self.counter -= 1
            if self.counter == 0 {
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

