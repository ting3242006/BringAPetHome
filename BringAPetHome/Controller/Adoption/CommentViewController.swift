//
//  CommentViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/23.
//

import UIKit
import Firebase

class CommentViewController: UIViewController {
    var adoptionId: String?
    var userData: UserModel?
    var creator: [String: Any] = [
        "id": "",
        "name": ""
    ]

    var dataBase = Firestore.firestore()
    var dbModels: [[String: Any]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var blackView = UIView(frame: UIScreen.main.bounds)
    
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        bgView.layer.cornerRadius = 25
        bgView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        fetchCommetData()
        blackViewDynamic()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCommetData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismiss(animated: true)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0
        }
    }
    
    @IBAction func sendComment(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        if commentTextField.text == "" {
            let alert = UIAlertController(title: "錯誤", message: "請輸入內容", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確認", style: .default))
            self.present(alert, animated: true)
        } else {
            addCommend(text: commentTextField.text ?? "")
            fetchCommetData()
            commentTextField.text = ""
            tableView.reloadData()
        }
    }
    
    @IBAction func closePopVC(_ sender: Any) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0
        }
        let presentingVC = self.presentingViewController
        self.dismiss(animated: false) {
            presentingVC?.tabBarController?.tabBar.isHidden = false
        }
    }
    
    func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        present(loginVC, animated: true)
    }
    
    func addCommend(text: String) {
        let comment = Firestore.firestore().collection("Comments")
        let document = comment.document()
        let timeInterval = Date()
        let data: [String: Any] = [ // postid userid
            Comments.commentId.rawValue: document.documentID,
            Comments.commentText.rawValue: text,
            Comments.creator.rawValue: creator,
            Comments.time.rawValue: NSDate().timeIntervalSince1970,
            Comments.adoptionId.rawValue: adoptionId ?? "",
            Comments.userUid.rawValue: Auth.auth().currentUser?.uid
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error\(error)")
            } else {
                print("Document update")
            }
        }
    }
    
    func fetchCommetData() {
        dataBase.collection("Comments").whereField("adoptionId", isEqualTo: adoptionId ?? "").order(by: "time", descending: true).getDocuments() { [weak self] (querySnapshot, error) in
            self?.dbModels = []
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    let commentDic = document.data()
                    self?.dbModels.insert(commentDic, at: 0)
                }
            }
        }
    }
    
    func blackViewDynamic() {
        blackView.backgroundColor = .black
        blackView.alpha = 0
        blackView.isUserInteractionEnabled = true
        presentingViewController?.view.addSubview(blackView)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0) {
            self.blackView.alpha = 0.5
        }
    }
}

extension CommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        dbModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell",
                                                       for: indexPath) as? CommentTableViewCell else { return UITableViewCell() }
        
        let firebaseData = dbModels[indexPath.row]
        let text: [String: Any] = firebaseData[Comments.commentText.rawValue] as? [String: Any] ?? [:]
        let time = firebaseData[Comments.time.rawValue] as? Double ?? 0.0
        let date = NSDate(timeIntervalSince1970: time)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        cell.commentUserImage.image = UIImage(named: "cat_ref")
        cell.layoutComment(name: "\(firebaseData[Comments.creator.rawValue] ?? "")",
                           text: "\(firebaseData[Comments.commentText.rawValue] ?? "")",
                           id: "\(firebaseData[Comments.commentId.rawValue] ?? "")",
                           date: formatter.string(from: date as Date))
        
        UserFirebaseManager.shared.fetchUser(userId: "\(firebaseData[Comments.userUid.rawValue] ?? "")")
        { result in
            switch result {
            case let .success(user):
                self.userData = user
                let url = self.userData?.image
                cell.commentUserImage.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.commentUserId.text = self.userData?.name
            case .failure(_):
                print("Error")
            }
        }
        return cell
    }
}
