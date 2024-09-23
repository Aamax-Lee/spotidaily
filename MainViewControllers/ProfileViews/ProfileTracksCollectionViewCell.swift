//
//  ProfileTracksCollectionViewCell.swift
//  musictime
//
//  Created by Aamax Lee on 6/5/2024.
//

import UIKit

//cell in collection view for profile view (specifically for songs)
class ProfileTracksCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
         
    }
    
    func configure(image: UIImage?, text: String) {
        imageView.image = image
        label.text = text
    }
}
