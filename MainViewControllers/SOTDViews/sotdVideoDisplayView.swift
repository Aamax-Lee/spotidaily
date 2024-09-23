//
//  sotdVideoDisplayView.swift
//  musictime
//
//  Created by Aamax Lee on 1/5/2024.
//

import UIKit
import AVKit

// custom view for displaying and controlling videos for SOTD section
class sotdVideoDisplayView: UIView {
        
        private var player: AVPlayer?       //avplayer for playing the video
        private var playerLayer: AVPlayerLayer? //display video content
        private let playButton = UIButton(type: .system)        //buttons to play and pause the video
        private let pauseButton = UIButton(type: .system)
            
        override init(frame: CGRect) {      //initialise the view with a frame
            super.init(frame: frame)
            setupUI()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupUI()
        }
        
    //configure the elements and add them to existing view
        private func setupUI() {
            // Add play button
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
            addSubview(playButton)
            
            // Add pause button
            pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
            addSubview(pauseButton)
            
            // Set initial button states
            playButton.isHidden = false
            pauseButton.isHidden = true
        }
        
//    Adjusts the layout of subviews when the view's bounds change
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
            playButton.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)   //set play and pause buttons to be the size of the video
            pauseButton.frame = CGRect(x: 0, y:  0, width: bounds.width, height: bounds.height)
        }
        
    // Configures the view with a video URL and initializes the player
        func configure(with videoURL: URL) {
            player = AVPlayer(url: videoURL)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer!)
        }
        
        @objc private func playButtonTapped() {
            playButton.isHidden = true
            pauseButton.isHidden = false
            player?.play()
        }
        
        @objc private func pauseButtonTapped() {
            playButton.isHidden = false
            pauseButton.isHidden = true
            player?.pause()
        }
        
    

        
    

}
