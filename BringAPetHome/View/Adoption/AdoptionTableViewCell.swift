//
//  AdoptionTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit

class AdoptionTableViewCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var adoptionAnimalImage: UIImageView!
    @IBOutlet weak var adoptionTitleLabel: UILabel!
    @IBOutlet weak var adoptionSex: UILabel!
    @IBOutlet weak var adoptionLocation: UILabel!
    @IBOutlet weak var adoptionContext: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
//    func layout(title: String, author: String, category: String ,date: String, content: String) {
//        articleTitleLabel.text = title
//        authorNameLabel.text = author
//        categoryLabel.text = category
//        createdTimeLabel.text = "\(date)"
//        articleContentLabel.text = content
//    }
}
