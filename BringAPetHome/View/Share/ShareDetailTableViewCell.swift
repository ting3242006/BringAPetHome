//
//  ShareDetailTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/26.
//

import UIKit

class ShareDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var shareImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
