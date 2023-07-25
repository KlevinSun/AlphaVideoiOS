//
//  PagViewController.swift
//  AlphaVideoiOSDemo
//
//  Created by sun.kai on 2023/7/25.
//  Copyright © 2023 lvpengwei. All rights reserved.
//

import UIKit
import libpag

class PagViewController: UIViewController {
    @IBOutlet weak var pagContainerView: UIView!
    
    private var pagView: PAGView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let pagFile = PAGFile.load(Bundle.main.path(forResource: "reference", ofType: "pag")) {
            self.pagView = PAGView(frame: pagContainerView.bounds)
            self.pagContainerView.addSubview(pagView)
            self.pagView.setRepeatCount(0)
            self.pagView.setComposition(pagFile)
            self.pagView.play()
        }
    }
}
