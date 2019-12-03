//
//  ViewController.swift
//  TMCLANExampleApp
//
//  Created by Richard Stelling on 03/12/2019.
//  Copyright © 2019 Richard Stelling. All rights reserved.
//

import UIKit
import TMCLANKit

class ViewController: UIViewController, TMCLANDelegate {

    @IBOutlet weak var createButton: UIButton!
    
    @IBOutlet weak var descoveredStack: UIStackView!
    
    private var count = 0
    private let randomPrefix = {
        ["Blue", "Red", "Purple", "Green", "White", "Black", "Orange", "Yellow"][Int.random(in: 0..<8)]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TMCLAN.shared.delegate = self
        
        NotificationCenter.default.addObserver(forName: .TMCDiscoveredLANGame, object: nil, queue: nil) { notification in
            
            print("Add LAN Game")
            
            let games = notification.userInfo?.values.compactMap { $0 as? GameInfo }
            
            DispatchQueue.main.async {
                
                self.descoveredStack.subviews.forEach { $0.removeFromSuperview() }
                games?.forEach { let l = UILabel(); l.text = $0.name; self.descoveredStack.addArrangedSubview(l) }
            }
        }

        NotificationCenter.default.addObserver(forName: .TMCRemovedLANGame, object: nil, queue: nil) { notification in
            
            print("Remove LAN Game")
            
            let games = notification.userInfo?.values.compactMap { $0 as? GameInfo }
            
            DispatchQueue.main.async {
                
                self.descoveredStack.subviews.forEach { $0.removeFromSuperview() }
                games?.forEach { let l = UILabel(); l.text = $0.name; self.descoveredStack.addArrangedSubview(l) }
            }
        }
        
        TMCLAN.shared.search()
    }

    @IBAction func onGameBroadcast(_ sender: UIButton) {
        
        if sender.isSelected {
            TMCLAN.shared.stopBroadcast()
            DispatchQueue.main.async {
                sender.setTitle("Broadcast Game", for: .normal)
                sender.isSelected = false
            }
        }
        else {
            
            count += 1
            
            do {
                let name = "Too Many Cooks Game \(randomPrefix) #\(count)"
                try TMCLAN.shared.broadcast(gameName: name)
                DispatchQueue.main.async {
                    sender.setTitle(name, for: .normal)
                    sender.isSelected = true
                }
            }
            catch {
                print("FAILED \(error)")
            }
        }
    }
    
    @IBAction func onStopBroadcast(_ sender: Any) {
        
        TMCLAN.shared.stopBroadcast()
        
        DispatchQueue.main.async {
            self.createButton.setTitle("Broadcast Game", for: .normal)
            self.createButton.isSelected = false
        }
    }
    
    func gameDscovered() {
        print("HELLO WORLD")
    }
}

