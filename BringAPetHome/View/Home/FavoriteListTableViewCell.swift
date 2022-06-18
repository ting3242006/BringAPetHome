//
//  FavoriteListTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/18.
//

import UIKit

class FavoriteListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var favoritePhoto: UIView!
    @IBOutlet weak var sex: UILabel!
    @IBOutlet weak var sterilization: UILabel!
    @IBOutlet weak var opendate: UILabel!
    @IBOutlet weak var place: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        favoritePhoto.layer.borderColor = #colorLiteral(red: 0.02589932643, green: 0.02589932643, blue: 0.02589932643, alpha: 0.7178938356).cgColor
        favoritePhoto.layer.borderWidth = 2
        favoritePhoto.clipsToBounds = true
        favoritePhoto.layer.cornerRadius = 25
        
        sex.backgroundColor = #colorLiteral(red: 0.1162804135, green: 0.8456138959, blue: 0.4789697292, alpha: 0.3300000131)
        sex.clipsToBounds = true
        sex.layer.cornerRadius = 15
        sex.layer.borderColor = #colorLiteral(red: 0.02589932643, green: 0.02589932643, blue: 0.02589932643, alpha: 0.7178938356).cgColor
        sex.layer.borderWidth = 2
        
        place.backgroundColor = #colorLiteral(red: 0.1162804135, green: 0.8456138959, blue: 0.4789697292, alpha: 0.3300000131)
        place.clipsToBounds = true
        place.layer.cornerRadius = 15
        place.layer.borderColor = #colorLiteral(red: 0.02589932643, green: 0.02589932643, blue: 0.02589932643, alpha: 0.7178938356).cgColor
        place.layer.borderWidth = 2
    }

}
