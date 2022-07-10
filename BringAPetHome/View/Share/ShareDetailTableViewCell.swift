//
//  ShareDetailTableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/26.
//

import UIKit

protocol ShareDetailTableViewCellDelegate: AnyObject {
    func tappedBlock(_ cell: UITableViewCell)
}

class ShareDetailTableViewCell: UITableViewCell {

    weak var shareDetailTableViewCellDelegate: ShareDetailTableViewCellDelegate?
    
    @IBOutlet weak var shareImageView: UIImageView!
    @IBOutlet weak var postTimeLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
//    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBAction func blockUser(_ sender: UIButton) {
        shareDetailTableViewCellDelegate?.tappedBlock(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
