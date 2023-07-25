//
//  TransparentVideoViewController.swift
//  AlphaVideoiOSDemo
//
//  Created by sun.kai on 2023/7/25.
//  Copyright © 2023 lvpengwei. All rights reserved.
//

import UIKit

class TransparentVideoViewController: UIViewController {
    @IBOutlet weak var videoView: SLPTransparentVideoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        videoView.setupView(name: "transparent", loop: true, videoType: .videoLeft_maskRight) { [weak self] in
            self?.videoView.play()
        }
    }
}
