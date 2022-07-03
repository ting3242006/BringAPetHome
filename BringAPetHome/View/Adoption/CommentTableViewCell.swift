//
//  CommentTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/23.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var commentUserImage: UIImageView!
    @IBOutlet weak var commentUserId: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commentUserImage.contentMode = .scaleAspectFill
        commentUserImage.layer.cornerRadius = 30
        commentUserImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func layoutComment(name: String, text: String, id: String, date: String) {
        commentTime.text = "\(date)"
        commentLabel.text = text
        commentUserId.text = id
    }
}
