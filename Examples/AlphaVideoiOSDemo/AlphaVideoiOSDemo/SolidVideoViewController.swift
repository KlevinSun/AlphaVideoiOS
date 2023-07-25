//
//  SolidVideoViewController.swift
//  AlphaVideoiOSDemo
//
//  Created by sun.kai on 2023/7/25.
//  Copyright © 2023 lvpengwei. All rights reserved.
//

import UIKit
import AVFoundation

class SolidVideoViewController: UIViewController {
    @IBOutlet weak var videoContainerView: UIView!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var didPlayToEndTimeObserver: NSObjectProtocol? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let videoPath = Bundle.main.path(forResource: "solid", ofType: "mp4") else {
            return
        }
        
        let videoURL = URL(fileURLWithPath: videoPath)
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoContainerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.shouldRasterize = true
        playerLayer?.rasterizationScale = UIScreen.main.scale
        videoContainerView.layer.addSublayer(playerLayer!)
        
        player?.play()
        
        didPlayToEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil, using: { _ in
            self.player?.seek(to: CMTime.zero) { _ in
                self.player?.play()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let observer = didPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
