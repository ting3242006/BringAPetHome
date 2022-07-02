//
//  FavoriteListTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/18.
//

import UIKit

class FavoriteListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var animalImageView: UIImageView!
    @IBOutlet weak var sex: UILabel!
    @IBOutlet weak var sterilization: UILabel!
    @IBOutlet weak var opendate: UILabel!
    @IBOutlet weak var place: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bgView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        bgView.layer.cornerRadius = 20
//        animalImageView.layer.borderColor = #colorLiteral(red: 0.02589932643, green: 0.02589932643, blue: 0.02589932643, alpha: 0.7178938356).cgColor
//        animalImageView.layer.borderWidth = 0.5
        animalImageView.clipsToBounds = true
//        containerView.layer.shadowColor = UIColor.darkGray.cgColor
//        containerView.layer.shadowOffset = CGSize(width: 0, height: 5)
//        containerView.layer.shadowRadius = 3
//        containerView.layer.shadowOpacity = 0.3
        animalImageView.layer.cornerRadius = 25
//        animalImageView.applyshadowWithCorner(containerView: contentView, cornerRadious: 25)
//        sex.backgroundColor = #colorLiteral(red: 0.1162804135, green: 0.8456138959, blue: 0.4789697292, alpha: 0.3300000131)
//        sex.clipsToBounds = true
//        sex.layer.cornerRadius = 5
//        sex.layer.borderColor = #colorLiteral(red: 0.02589932643, green: 0.02589932643, blue: 0.02589932643, alpha: 0.7178938356).cgColor
//        sex.layer.borderWidth = 0.5
        
//        place.backgroundColor = #colorLiteral(red: 0.1162804135, green: 0.8456138959, blue: 0.4789697292, alpha: 0.3300000131)
//        place.clipsToBounds = true
//        place.layer.cornerRadius = 5
//        place.layer.borderColor = #colorLiteral(red: 0.02589932643, green: 0.02589932643, blue: 0.02589932643, alpha: 0.7178938356).cgColor
//        place.layer.borderWidth = 0.5
    }

}
