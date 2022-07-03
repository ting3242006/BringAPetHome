//
//  AdoptionTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit
import Kingfisher

class AdoptionTableViewCell: UITableViewCell {
    
//    struct DownloadData: Codable {
//        let age: Age
//        let sex: Sex
//        let petable: Petable
//    }
    
//    enum Age: String, Codable {
//        case threeMonthOld = "三個月內"
//        case sixMonthOld = "六個月內"
//        case oneYearOld = "六個月到一年"
//        case biggerThanOneYear = "一歲以上"
//
//        var ageInt: Int {
//            switch self {
//            case .threeMonthOld:
//                return 0
//            case .sixMonthOld:
//                return 1
//            case .oneYearOld:
//                return 2
//            case .biggerThanOneYear:
//                return 3
//            default:
//                return 0
//            }
//        }
//    }
    
//    enum Sex: String, Codable {
//        case boy = "Boy"
//        case girl = "Girl"
//
//        var sexInt: Int {
//            switch self {
//            case .boy:
//                return 0
//            case .girl:
//                return 1
//            default:
//                return 0
//            }
//        }
//    }
    
    var showSex: String?
    var showAge: String?
    var showPetable: String?
    
//    enum Petable: String, Codable {
//        case adopt = "送養"
//        case adopted = "已領養"
//
//        var petableInt: Int {
//            switch self {
//            case .adopt:
//                return 0
//            case .adopted:
//                return 1
//            default:
//                return 0
//            }
//        }
//    }

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
    
    func layout(location: String, date: String, content: String, imageFileUrl: String, age: Age, sex: Sex, petable: Petable) {
        
        adoptionLocation.text = location
        adoptionAnimalImage.kf.setImage(with: URL(string: imageFileUrl))
        createdTimeLabel.text = "\(date)"
        adoptionContent.text = content
        ageLabel.text = age.title
        adoptionSexLabel.text = sex.sexTitle
//        petableLabel.text = petable.petableTitle
    }
    
    func setupPetable(petable: Int) -> String {
        switch petable {
        case 0: return "送養"
        case 1: return "已領養"
        default: return ""
        }
//        let petable = showPetable
//        petableLabel.text = petable
    }
    
    func setupAge(age: Int) -> String {
        switch age {
        case 0: return "三個月內"
        case 1: return "三個月到六個月"
        case 2: return "六個月到一歲"
        case 3: return "一歲以上"
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
