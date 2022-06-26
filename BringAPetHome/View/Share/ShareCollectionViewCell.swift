//
//  ShareCollectionViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/24.
//

import UIKit

class ShareCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "\(ShareCollectionViewCell.self)"
    @IBOutlet weak var shareImage: UIImageView!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    static let width = floor((UIScreen.main.bounds.width - 4 * 2) / 3)
    
    override func awakeFromNib() {
          super.awakeFromNib()
          imageWidthConstraint.constant = Self.width
      }
}
