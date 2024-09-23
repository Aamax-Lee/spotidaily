//
//  SOTDTableViewCell.swift
//  musictime
//
//  Created by Aamax Lee on 30/4/2024.
//

import UIKit
import AVFoundation

class SOTDTableViewCell: UITableViewCell {
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    let videoContainerView = UIView()
    let nameLabel = UILabel()
//    @IBOutlet weak var userImage: UIImage!
//    @IBOutlet weak var userName: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    
    private func setupViews() {
            // Setup nameLabel
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            nameLabel.textColor = .black
            contentView.addSubview(nameLabel)
            
            // Setup videoContainerView
            videoContainerView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(videoContainerView)
            
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

                videoContainerView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
                videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                videoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                videoContainerView.heightAnchor.constraint(equalToConstant: 200) // Set a fixed height for the player
            ])
        }
        
        func configureWith(videoUrl: URL, name: String) {
            nameLabel.text = name
            
            // Configure the AVPlayer
            player = AVPlayer(url: videoUrl)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = videoContainerView.bounds
            playerLayer?.videoGravity = .resizeAspect
            
            if let layer = playerLayer {
                videoContainerView.layer.addSublayer(layer)
            }
        }
        
        func play() {
            player?.play()
        }
        
        func stop() {
            player?.pause()
            player?.seek(to: .zero)
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            playerLayer?.removeFromSuperlayer()
            player?.pause()
            player = nil
            playerLayer = nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = videoContainerView.bounds
        }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
