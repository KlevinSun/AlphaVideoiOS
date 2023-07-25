//
//  SLPTransparentVideoView.swift
//  SLPFramework
//
//  Created by sun.kai on 2023/7/20.
//

import UIKit
import AVFoundation

enum SLPTransparentVideoType {
    case videoUp_maskDown
    case videoLeft_maskRight
}

class SLPTransparentVideoView: UIView {
    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    private var isLoop: Bool = true
    private var videoType: SLPTransparentVideoType = .videoLeft_maskRight
    private var name: String = "" {
        didSet {
            loadVideo()
        }
    }
    private var loadFinished: (() -> Void)?
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    private var player: AVPlayer? {
        get {
            return playerLayer.player
        }
    }
    private var asset: AVAsset?
    
    private var playerItem: AVPlayerItem? = nil {
        willSet {
            player?.pause()
        }
        didSet {
            player?.seek(to: CMTime.zero)
            setupPlayerItem()
            if isLoop {
                setupLooping()
            } else if let observer = self.didPlayToEndTimeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            player?.replaceCurrentItem(with: playerItem)
            loadFinished?()
        }
    }
    
    private var didPlayToEndTimeObserver: NSObjectProtocol? = nil {
        willSet(newObserver) {
            if let observer = didPlayToEndTimeObserver, didPlayToEndTimeObserver !== newObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    public init(with name: String, loop: Bool = true, videoType: SLPTransparentVideoType = .videoLeft_maskRight, loadFinished: (() -> Void)?) {
        super.init(frame: .zero)
        commonInit()
        setupView(name: name, loop: loop, videoType: videoType, loadFinished: loadFinished)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public func setupView(name: String, loop: Bool = true, videoType: SLPTransparentVideoType = .videoLeft_maskRight, loadFinished: (() -> Void)?) {
        self.isLoop = loop
        self.videoType = videoType
        if name.hasSuffix(".mp4"), let index = name.lastIndex(of: ".") {
            self.name = String(name[..<index])
        } else {
            self.name = name
        }
        self.loadFinished = loadFinished
    }
    
    private func loadVideo() {
        guard !name.isEmpty else {
            return
        }
        
        guard let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") else { return }
        self.asset = AVURLAsset(url: videoURL)
        self.asset?.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) { [weak self] in
            guard let self = self, let asset = self.asset else {
                return
            }
            DispatchQueue.main.async {
                self.playerItem = AVPlayerItem(asset: asset)
            }
        }
    }
    
    public func play() {
        guard let _ = self.playerItem else {
            return
        }
        player?.play()
    }
    
    public func pause() {
        guard let _ = self.playerItem else {
            return
        }
        player?.pause()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        playerLayer.pixelBufferAttributes = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        playerLayer.player = AVPlayer()
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
    }
    
    @objc private func tapAction() {
        guard let player = player else {
            return
        }
        
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }
    
    private func setupLooping() {
        guard let playerItem = self.playerItem, let player = self.player else {
            return
        }
        
        didPlayToEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil, using: { _ in
            player.seek(to: CMTime.zero) { _ in
                player.play()
            }
        })
    }
    private func setupPlayerItem() {
        guard let playerItem = playerItem else {
            return
        }
        let tracks = playerItem.asset.tracks
        guard tracks.count > 0 else {
            print("no tracks")
            return
        }
        var videoSize: CGSize
        switch videoType {
        case .videoUp_maskDown:
            videoSize = CGSize(width: tracks[0].naturalSize.width, height: tracks[0].naturalSize.height * 0.5)
        case .videoLeft_maskRight:
            videoSize = CGSize(width: tracks[0].naturalSize.width * 0.5, height: tracks[0].naturalSize.height)
        }
        
        guard videoSize.width > 0 && videoSize.height > 0 else {
            print("video size is zero")
            return
        }
        let composition = AVMutableVideoComposition(asset: playerItem.asset, applyingCIFiltersWithHandler: { [weak self] request in
            guard let strongSelf = self else {
                return
            }
            let filter = SLPTransparentFrameFilter()
            let sourceRect = CGRect(origin: .zero, size: videoSize)
            
            switch strongSelf.videoType {
            case .videoUp_maskDown:
                let alphaRect = sourceRect.offsetBy(dx: 0, dy: sourceRect.height)
                filter.inputImage = request.sourceImage.cropped(to: alphaRect)
                    .transformed(by: CGAffineTransform(translationX: 0, y: -sourceRect.height))
                filter.maskImage = request.sourceImage.cropped(to: sourceRect)
            case .videoLeft_maskRight:
                let alphaRect = sourceRect.offsetBy(dx: sourceRect.width, dy: 0)
                filter.inputImage = request.sourceImage.cropped(to: sourceRect)
                filter.maskImage = request.sourceImage.cropped(to: alphaRect)
                    .transformed(by: CGAffineTransform(translationX: -sourceRect.width, y: 0))

            }
            return request.finish(with: filter.outputImage!, context: nil)
        })
        
        composition.renderSize = videoSize
        playerItem.videoComposition = composition
        playerItem.seekingWaitsForVideoCompositionRendering = true
    }
    
    deinit {
        self.playerItem = nil
        if let observer = self.didPlayToEndTimeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}

class SLPTransparentFrameFilter: CIFilter {
    static var kernel: CIColorKernel? = {
        return CIColorKernel(source: """
            kernel vec4 alphaFrame(__sample s, __sample m) {
              return vec4(s.rgb, m.r);
            }
            """)
    }()
    
    var inputImage: CIImage?
    var maskImage: CIImage?
    
    override var outputImage: CIImage? {
        let kernel = SLPTransparentFrameFilter.kernel!
        guard let inputImage = inputImage, let maskImage = maskImage else {
            return nil
        }
        let args = [inputImage as AnyObject, maskImage as AnyObject]
        return kernel.apply(extent: inputImage.extent, arguments: args)
    }
}
