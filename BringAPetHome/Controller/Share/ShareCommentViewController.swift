//
//  ShareCommentViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/27.
//

import UIKit
import Firebase

class ShareCommentViewController: UIViewController {
    
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var commentList = [ShareComment]()
    var postId: String? = ""
    var userData: UserModel?
    
    // var shareModel: ShareModel?
    // segue or prepare 傳值
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blackView = UIView(frame: UIScreen.main.bounds)
        blackView.backgroundColor = .black
        blackView.alpha = 0
        presentingViewController?.view.addSubview(blackView)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            blackView.alpha = 0.5
        }
        
        bgView.layer.cornerRadius = 25
        bgView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tableView.dataSource = self
        tableView.delegate = self
        //        ShareManager.shared.fetchSharingComment(completion: { commentList in self.commentList = commentList ?? []
        //            self.tableView.reloadData()
        //        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchSharingComment()
        //        ShareManager.shared.fetchSharingComment(completion: { commentList in self.commentList = commentList ?? []
        //
        //            self.tableView.reloadData()
        //        })
    }
    
    @IBAction func closeView(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func sendShareComment(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        if commentTextField.text == "" {
            let alert = UIAlertController(title: "錯誤", message: "請輸入內容", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確認", style: .default))
            self.present(alert, animated: true)
        } else {
            let userUid = Auth.auth().currentUser?.uid ?? ""
            ShareManager.shared.addComments(uid: userUid, postId: postId ?? "", comments: commentTextField.text ?? "")
            fetchSharingComment()
            commentTextField.text = ""
            tableView.reloadData()
        }
    }
    
    func fetchSharingComment() {
        ShareManager.shared.fetchSharingComment(postId: postId ?? "") { [weak self] result in
            switch result {
            case .success(let shareComments):
                self?.commentList = shareComments
                self?.tableView.reloadData()
            case .failure:
                print("Can't fetch data")
            }
        }
    }
    
    func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        present(loginVC, animated: true)
    }
}

extension ShareCommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return commentList.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareCommentTableViewCell",
                                                       for: indexPath) as? ShareCommentTableViewCell else { return UITableViewCell() }
        //        cell.userImageView.image = UIImage(named: "dketch-4")
        cell.contentLabel.text = commentList[indexPath.row].text
        //        cell.userNameLabel.text = commentList[indexPath.row].userUid
        cell.commentTimeLabel.text = commentList[indexPath.row].time.displayTimeInSocialMediaStyle()
        
        UserFirebaseManager.shared.fetchUser(userId: commentList[indexPath.row].userUid) { result in
            switch result {
            case let .success(user):
                self.userData = user
                let url = self.userData?.image
                cell.userImageView.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.userNameLabel.text = self.userData?.name
            case .failure(_):
                print("Error")
            }
        }
        return cell
    }
}
