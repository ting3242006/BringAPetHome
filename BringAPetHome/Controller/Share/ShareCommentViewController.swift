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
    var blackView = UIView(frame: UIScreen.main.bounds)
    var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    
    // segue or prepare 傳值
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        blackViewDynamic()
        layout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSharingComment()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismiss(animated: true)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0
        }
    }
    
    @IBAction func closeView(_ sender: Any) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0
        }
        let presentingVC = self.presentingViewController
        self.dismiss(animated: false) {
            presentingVC?.tabBarController?.tabBar.isHidden = false
        }
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
    
    private func fetchSharingComment() {
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
    
    private func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        present(loginVC, animated: true)
    }
    
    private func blackViewDynamic() {
        blackView.backgroundColor = .black
        blackView.alpha = 0
        blackView.isUserInteractionEnabled = true
 
        presentingViewController?.view.addSubview(blackView)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0.5
        }
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
    }
    
    private func layout() {
        bgView.layer.cornerRadius = 25
        bgView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    @objc func dismissController() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
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
        cell.contentLabel.text = commentList[indexPath.row].text
        cell.commentTimeLabel.text = commentList[indexPath.row].time.displayTimeInSocialMediaStyle()
        
        UserFirebaseManager.shared.fetchUser(userId: commentList[indexPath.row].userUid) { result in
            switch result {
            case let .success(user):
                self.userData = user
                let url = self.userData?.image
                cell.userImageView.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.userNameLabel.text = self.userData?.name
            case .failure:
                print("Error")
            }
        }
        return cell
    }
}
