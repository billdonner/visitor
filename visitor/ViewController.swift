//
//  ViewController.swift
//  visitor
//
//  Created by bill donner on 6/27/18.
//  Copyright © 2018 bill donner. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController {
    var locMinder:LocMinder!
    var gameTimer: Timer!
    var counter = 0
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @objc func pollCycle () {
        
        counter += 1
        
        let llc = LastKnownLocation.fetchfromUserDefaults()
        if let llc = llc {
            self.topLabel.text = "Ping Server cycle# \(self.counter) \(llc)"
            print("Ping Server cycle# \(self.counter) \(llc)")
        }
        else {
            self.topLabel.text = "\(self.counter) warming..."
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(pollCycle), userInfo: nil, repeats: true)
        pollCycle()
        
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Override point for customization after application launch.
        // if not simulator, open console pipe
        
        locMinder = LocMinder(){ str in
            self.bottomLabel.text = str
            self.bottomLabel.setNeedsLayout()
            self.locMinder.startAlways(self)
        }
        
        locMinder.start (mode:.eachUpdate)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

