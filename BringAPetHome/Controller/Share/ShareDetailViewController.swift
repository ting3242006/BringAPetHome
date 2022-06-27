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
    let selectedBackgroundView = UIView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedBackgroundView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        shareManager.fetchSharing(completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
//        refresh()
    }
    
    @IBAction func showComment(_ sender: Any) {
        
    }
    
    func refresh() {
        let refreshControl = UIRefreshControl()
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.yellow]
        refreshControl.attributedTitle = NSAttributedString(string: "正在更新", attributes: attributes)
        refreshControl.tintColor = UIColor.white
        refreshControl.backgroundColor = UIColor.black
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchData), for: UIControl.Event.valueChanged)
    }
    
    @objc func fetchData() {
        shareManager.fetchSharing(completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
    }
}
    // DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
    //    refreshControl.endRefreshing()
    // } 要寫停止refresh

extension ShareDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shareList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareDetailTableViewCell",
                                                       for: indexPath) as? ShareDetailTableViewCell else { return UITableViewCell() }
        let urls = shareList[indexPath.row].shareImageUrl
        cell.shareImageView.kf.setImage(with: URL(string: urls), placeholder: UIImage(named: "dketch-4"))
        cell.userNameLabel.text = "Ting"
//        cell.timeLabel.text = shareList[indexPath.row].createdTime
        cell.contentLabel.text = shareList[indexPath.row].shareContent
        cell.userImageView.image = UIImage(named: "dketch-1")
        cell.selectedBackgroundView = selectedBackgroundView
        return cell
    }
}