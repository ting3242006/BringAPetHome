//
//  FavoriteListTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/18.
//

import UIKit

class FavoriteListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var animalImageView: UIImageView!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var sterilization: UILabel!
    @IBOutlet weak var opendate: UILabel!
    @IBOutlet weak var place: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var sexLabel: UILabel!
    @IBOutlet weak var sexImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        bgView.layer.cornerRadius = 15
        animalImageView.layer.cornerRadius = 15
        animalImageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
    }

}
