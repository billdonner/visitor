//
//  ViewController.swift
//  visitor
//
//  Created by bill donner on 6/27/18.
//  Copyright © 2018 bill donner. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var gameTimer: Timer!
    
    var counter = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        runTimedCode()

    }
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @objc func runTimedCode () {
        
          counter += 1
          self.topLabel.text = "\(self.counter)"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("viewdidload")
        #if !(targetEnvironment(simulator))
        let piper = Piper()
        piper.openConsolePipe(){ str in
          
            self.bottomLabel.text = str
          
        }
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

