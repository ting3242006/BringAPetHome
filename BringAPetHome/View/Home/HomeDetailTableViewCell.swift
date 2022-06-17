//
//  HomeDetailTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/16.
//

import UIKit

class HomeDetailTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "\(HomeDetailTableViewCell.self)"
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sexLabel: UILabel!
    @IBOutlet weak var animalIdLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var areaPkidLabel: UILabel!
    @IBOutlet weak var bodytypeLabel: UILabel!
    @IBOutlet weak var colourLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var remarkLabel: UILabel!
    @IBOutlet weak var opendateLabel: UILabel!
    @IBOutlet weak var shelterNameLabel: UILabel!
    @IBOutlet weak var albumFileImageView: UIImageView!
    @IBOutlet weak var shelterAddressLabel: UILabel!
    @IBOutlet weak var shelterTel: UILabel!
    @IBOutlet weak var shelterTelLabel: UILabel!
    @IBOutlet weak var animalVarietyLabel: UILabel!
    @IBOutlet weak var animalSterilizationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cDateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
