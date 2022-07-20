//
//  HomeCollectionViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "\(HomeCollectionViewCell.self)"
    
    let backgroundImageView = UIImageView()
    let shelterImageView = UIImageView()
    let sexLabel = UILabel()
    let placeLabel = UILabel()
    let colorLabel = UILabel()
    let sexImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundImageView.backgroundColor = .white
        sexLabel.font = .systemFont(ofSize: 12)
        sexLabel.textColor = .clear
        placeLabel.font = .systemFont(ofSize: 13)
        placeLabel.numberOfLines = 0
        placeLabel.textColor = UIColor(named: "DarkGreen")
        colorLabel.font = .systemFont(ofSize: 13)
        colorLabel.textColor = .systemGray
        
        contentView.addSubview(backgroundImageView)
        backgroundImageView.addSubview(shelterImageView)
        backgroundImageView.addSubview(sexLabel)
        backgroundImageView.addSubview(placeLabel)
        backgroundImageView.addSubview(sexImageView)
        backgroundImageView.addSubview(colorLabel)
        backgroundImageView.layer.cornerRadius = 10
        backgroundImageView.clipsToBounds = true
        backgroundImageView.anchor(top: contentView.topAnchor,
                                   leading: contentView.leadingAnchor,
                                   bottom: contentView.bottomAnchor,
                                   trailing: contentView.leadingAnchor,
                                   padding: .init(top: 5, left: -1, bottom: 5, right: 5), width: 170, height: 200)
        shelterImageView.anchor(top: backgroundImageView.topAnchor,
                                leading: backgroundImageView.leadingAnchor,
                                trailing: backgroundImageView.trailingAnchor,
                                padding: .init(top: 0, left: 0, bottom: 0, right: 0),
                                height: 150)
        sexLabel.anchor(top: shelterImageView.bottomAnchor,
                        leading: sexImageView.trailingAnchor,
                        padding: .init(top: 12, left: 10, bottom: 0, right: 0),
                        height: 22)
        placeLabel.anchor(top: shelterImageView.bottomAnchor,
                          trailing: backgroundImageView.trailingAnchor,
                          padding: .init(top: 12, left: 10, bottom: 0, right: 15),
                          height: 22)
        sexImageView.anchor(top: shelterImageView.bottomAnchor,
                            leading: shelterImageView.leadingAnchor,
                            padding: .init(top: 12, left: 10, bottom: 0, right: 0),
                            width: 22, height: 22)
        sexImageView.contentMode = .scaleAspectFit
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
