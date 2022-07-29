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
    
    let selectedBackgroundView = UIView()
    var refreshControl: UIRefreshControl!
    var publishButton = UIButton()
    var shareManager = ShareManager.shared
    var dataBase = Firestore.firestore()
    var shareList = [ShareModel]()
    var shareItem: ShareModel?
    var user = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedBackgroundView.backgroundColor = UIColor.clear
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setButtonLayout()
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchShareData()
        tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func showComment(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showLoginVC()
        } else {
            return
        }
    }
    
    @IBSegueAction func sentCommentData(_ coder: NSCoder, sender: Any?) -> ShareCommentViewController? {
        let controller = ShareCommentViewController(coder: coder)
        let button = sender as? UIButton
        if let point = button?.convert(CGPoint.zero, to: tableView),
           let indexPath = tableView.indexPathForRow(at: point) {
            let shareModel = shareList[indexPath.row]
            controller?.postId = shareModel.postId
            tabBarController?.tabBar.isHidden = true
        }
        return controller
    }
    
    @objc func didTapped() {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postSharingVC = mainStoryboard.instantiateViewController(withIdentifier: "PostSharingViewController") as? PostSharingViewController else { return }
        self.navigationController?.pushViewController(postSharingVC, animated: true)
    }
    
    @objc func fetchShareData() {
        shareManager.fetchSharing(completion: { shareList in
            self.shareList = shareList ?? []
            self.shareList.sort {
                $0.createdTime.seconds > $1.createdTime.seconds
            }
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
            let index = self.shareList.firstIndex {
                $0.postId == self.shareItem?.postId
            }
            if let index = index {
                self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: false)
            }
        })
    }
    
    private func setButtonLayout() {
        view.addSubview(publishButton)
        publishButton.backgroundColor = UIColor(named: "HoneyYellow")
        publishButton.layer.cornerRadius = 30
        publishButton.tintColor = .white
        publishButton.setImage(UIImage(systemName: "plus"), for: .normal)
        publishButton.addTarget(self, action: #selector(didTapped), for: .touchUpInside)
        publishButton.anchor(bottom: view.bottomAnchor,
                             trailing: view.trailingAnchor,
                             padding: .init(top: 0, left: 0, bottom: 95, right: 20),
                             width: 60, height: 60)
    }
    
    private func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        self.navigationController?.present(loginVC, animated: true)
    }
    
    private func refresh() {
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchShareData), for: UIControl.Event.valueChanged)
    }
    
    private func confirmBlocked(userId: String) {
        let alert  = UIAlertController(title: "封鎖用戶", message: "確認要封鎖此用戶嗎? 封鎖後將看不到此用戶貼文", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "確認", style: .destructive) { (_) in
            self.dataBase.collection("User").document(Auth.auth().currentUser?.uid ?? "").updateData(["blockedUser": FieldValue.arrayUnion([userId])])
            self.fetchShareData()
            self.tableView.reloadData()
        }
        let noAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        
        present(alert, animated: true, completion: nil)
        tableView.reloadData()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareDetailTableViewCell",
                                                       for: indexPath) as? ShareDetailTableViewCell else { return UITableViewCell() }
        cell.shareDetailTableViewCellDelegate = self
        let urls = shareList[indexPath.row].shareImageUrl
        cell.shareImageView.kf.setImage(with: URL(string: urls), placeholder: UIImage(named: "dketch-4"))
        cell.contentLabel.text = shareList[indexPath.row].shareContent
        cell.selectedBackgroundView = selectedBackgroundView
        cell.userImageView.layer.cornerRadius = 15
        
        UserFirebaseManager.shared.fetchUser(userId: shareList[indexPath.row].userUid) { result in
            switch result {
            case let .success(user):
                let url = user.image
                cell.userImageView.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.userNameLabel.text = user.name
            case .failure(_):
                print("Error")
            }
        }
        return cell
    }
}

// delegate blockUser
extension ShareDetailViewController: ShareDetailTableViewCellDelegate {
    func tappedBlock(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        print("confirmBlocked", shareList[indexPath.row].userUid)
        self.confirmBlocked(userId: shareList[indexPath.row].userUid)
    }
}
