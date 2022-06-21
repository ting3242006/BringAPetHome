//
//  HomeDetailTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/16.
//

import UIKit

protocol HomeDetailTableViewCellDelegate: AnyObject {
    func heartButtonTapped()
}

class HomeDetailTableViewCell: UITableViewCell {
    weak var delegate: HomeDetailTableViewCellDelegate?
    static let reuseIdentifier = "\(HomeDetailTableViewCell.self)"
    var link: HomeDetailViewController?    
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
    @IBOutlet weak var animalVarietyLabel: UILabel!
    @IBOutlet weak var animalSterilizationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cDateLabel: UILabel!
    
    var heartButton = UIButton(type: .system)

    override func awakeFromNib() {
        super.awakeFromNib()
        
        heartButton = makeTabButton(imageName: "heartFill", unselectedImageName: "heart")
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        addSubview(heartButton)
        heartButton.anchor(
            bottom: albumFileImageView.bottomAnchor,
            trailing: albumFileImageView.trailingAnchor,
            padding: .init(top: 0, left: 0, bottom: 32, right: 32),
            width: 40, height: 36
        )
    }

    func makeTabButton(imageName: String, unselectedImageName: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: imageName), for: .selected)
        button.setImage(UIImage(named: unselectedImageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }
    
    // MARK: - Action
    @objc func heartButtonTapped() {
//        link?.someMethodIWantToCall(cell: self)
        heartButton.isSelected = !heartButton.isSelected
        delegate?.heartButtonTapped()
    }
}
