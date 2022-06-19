//
//  AdoptionTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit

class AdoptionTableViewCell: UITableViewCell {

    @IBOutlet weak var userPhoto: UIView!
    @IBOutlet weak var adoptionTitleLabel: UILabel!
    @IBOutlet weak var adoptionAnimalView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
