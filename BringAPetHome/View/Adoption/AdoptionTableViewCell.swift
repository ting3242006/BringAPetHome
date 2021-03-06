//
//  AdoptionTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit
import Kingfisher

protocol AdoptionTableViewCellDelegate: AnyObject {
    func tappedBlock(_ cell: UITableViewCell)
}

class AdoptionTableViewCell: UITableViewCell {
    
    weak var adoptionTableViewCellDelegate: AdoptionTableViewCellDelegate?
    var showSex: String?
    var showAge: String?
    var showPetable: String?

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var adoptionAnimalImage: UIImageView!
    @IBOutlet weak var petableLabel: UILabel!
    @IBOutlet weak var adoptionSexLabel: UILabel!
    @IBOutlet weak var adoptionLocation: UILabel!
    @IBOutlet weak var adoptionContent: UILabel!
    @IBOutlet weak var createdTimeLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var sexIconImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = 15
        userImageView.clipsToBounds = true
        adoptionAnimalImage.layer.cornerRadius = 15
        adoptionAnimalImage.clipsToBounds = true        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func blockUserButton(_ sender: UIButton) {
        adoptionTableViewCellDelegate?.tappedBlock(self)
    }
    
    func layout(location: String, date: String, content: String, imageFileUrl: String, age: Age, sex: Sex, petable: Petable) {
        adoptionLocation.text = location
        adoptionAnimalImage.kf.setImage(with: URL(string: imageFileUrl))
        createdTimeLabel.text = "\(date)"
        adoptionContent.text = content
        ageLabel.text = age.title
        adoptionSexLabel.text = sex.sexTitle
    }
    
    func setupPetable(petable: Int) -> String {
        switch petable {
        case 0: return "??????"
        case 1: return "?????????"
        default: return ""
        }
//        let petable = showPetable
//        petableLabel.text = petable
    }
    
    func setupAge(age: Int) -> String {
        switch age {
        case 0: return "????????????"
        case 1: return "?????????????????????"
        case 2: return "??????????????????"
        case 3: return "????????????"
        default: return ""
        }
        let age = showAge
        ageLabel.text = age
    }
    
    func setupSex(sex: Int) -> String {
        switch sex {
        case 0: return "Boy"
        case 1: return "Girl"
        default: return ""
        }
        let sex = showSex
        adoptionSexLabel.text = sex
    }
}
