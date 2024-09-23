//
//  ProfileCollectionViewCell.swift
//  musictime
//
//  Created by Aamax Lee on 1/5/2024.
//

import UIKit

//cell in collection view for profile view (specifically for artists)
class ProfileCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
         
//        make iamges round
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.layer.masksToBounds = true
    }
    
    func configure(image: UIImage?, text: String) {
        imageView.image = image
        label.text = text
    }
}
