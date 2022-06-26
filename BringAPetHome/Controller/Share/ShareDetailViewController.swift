//
//  ShareDetailViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/26.
//

import UIKit
import Firebase
import FirebaseFirestore

class ShareDetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var shareManager = ShareManager()
    var dataBase = Firestore.firestore()
    var shareList = [ShareModel]()
    var shareItem: ShareModel?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        shareManager.fetchSharing(completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
    }
}


extension ShareDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shareList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareDetailTableViewCell", for: indexPath) as? ShareDetailTableViewCell else { return UITableViewCell() }
        let urls = shareList[indexPath.row].shareImageUrl
        cell.shareImageView.kf.setImage(with: URL(string: urls), placeholder: UIImage(named: "dketch-4"))
        cell.userNameLabel.text = "Ting"
//        cell.timeLabel.text = shareList[indexPath.row].createdTime
        cell.contentLabel.text = shareList[indexPath.row].shareContent
        cell.userImageView.image = UIImage(named: "dketch-1")
        return cell
    }
}
