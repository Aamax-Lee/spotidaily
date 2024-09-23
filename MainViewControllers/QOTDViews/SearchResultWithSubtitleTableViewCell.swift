//
//  SearchResultWithSubtitleTableViewCell.swift
//  musictime
//
//  Created by Aamax Lee on 14/5/2024.
//

import UIKit

//model for what search results would be
struct SearchResultWithSubtitleTableViewCellViewModel {
    let title: String
    let subtitle: String
    let imageURL: URL?
}

//each cell in the search results, containing song name, artist name and song image
class SearchResultWithSubtitleTableViewCell: UITableViewCell {
    static let identifier = "SearchResultWithSubtitleTableViewCell"
    
    // Label for displaying the title
    private let label: UILabel = {
       let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    // Label for displaying the subtitle
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    // Image view for displaying the result image
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        add the subviews (elements above)
        contentView.addSubview(label)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(iconImageView)
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
    }
    
    // Required initializer, not used in this class
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Layout subviews, setting the frames for the elements
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageSize: CGFloat = contentView.bounds.height - 10
        
        iconImageView.frame = CGRect(
            x: 10,
            y: 5,
            width: imageSize,
            height: imageSize
            )
        
        let labelHeight = contentView.bounds.height / 2     //to fit both title and subtitle above and below each other
        
        label.frame = CGRect(
            x: iconImageView.frame.maxX + 10,
            y: 0,
            width: contentView.bounds.width - iconImageView.frame.maxX - 15,
            height: labelHeight
            )
        
        subtitleLabel.frame = CGRect(
            x: iconImageView.frame.maxX + 10,
            y: label.frame.maxY,
            width: contentView.bounds.width - iconImageView.frame.maxX - 15,
            height: labelHeight
            )
    }
    
    // Prepare for reuse by resetting cell properties
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        label.text = nil
        subtitleLabel.text = nil
    }
    
    // Configure cell with view model data, setting what the text and iimage should be
    func configure(with viewModel: SearchResultWithSubtitleTableViewCellViewModel) {
        label.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        if let imageUrl = viewModel.imageURL {
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                if let error = error {
                    print("Error downloading image: \(error)")
                    return
                }
                
                guard let imageData = data else {
                    print("No image data received")
                    return
                }
                
                DispatchQueue.main.async {
                    // Create UIImage from imageData and set it to iconImageView
                    if let image = UIImage(data: imageData) {
                        self.iconImageView.image = image
                    } else {
                        print("Failed to create UIImage from data")
                    }
                }
            }.resume()
        } else {
            print("Image URL is nil")
        }
    }

}
