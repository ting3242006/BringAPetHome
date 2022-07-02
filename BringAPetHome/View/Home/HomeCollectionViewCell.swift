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
        backgroundImageView.anchor(top: contentView.topAnchor,
                                   leading: contentView.leadingAnchor,
                                   bottom: contentView.bottomAnchor,
                                   trailing: contentView.leadingAnchor,
                                   padding: .init(top: 5, left: 5, bottom: 5, right: 5), width: 160, height: 245)
        shelterImageView.anchor(top: backgroundImageView.topAnchor,
                                leading: backgroundImageView.leadingAnchor,
                                trailing: backgroundImageView.trailingAnchor,
                                padding: .init(top: 5, left: 5, bottom: 0, right: 5),
                                height: 150)
        sexLabel.anchor(top: shelterImageView.bottomAnchor,
                        leading: shelterImageView.leadingAnchor,
                        trailing: shelterImageView.trailingAnchor,
                        padding: .init(top: 12, left: 0, bottom: 0, right: 0),
                        height: 22)
        colorLabel.anchor(top: shelterImageView.bottomAnchor,
                        leading: shelterImageView.leadingAnchor,
                        trailing: shelterImageView.trailingAnchor,
                        padding: .init(top: 12, left: 0, bottom: 0, right: 0),
                        height: 22)
        placeLabel.anchor(top: sexLabel.bottomAnchor,
                          leading: backgroundImageView.leadingAnchor,
                          trailing: backgroundImageView.trailingAnchor,
                          padding: .init(top: 8, left: 4, bottom: 0, right: 2),
                          height: 22)
        sexImageView.anchor(bottom: backgroundImageView.bottomAnchor,
                            trailing: backgroundImageView.trailingAnchor,
                            padding: .init(top: 0, left: 0, bottom: 28, right: 8),
                            width: 18, height: 20)
        sexImageView.contentMode = .scaleAspectFit
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
