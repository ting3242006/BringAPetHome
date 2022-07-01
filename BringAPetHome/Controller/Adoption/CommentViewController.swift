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
    
    enum Comments: String {
        case commentText = "commentText"
        case commentId = "commentId"
        case adoptionId = "adoptionId"
        case time = "time"
        case creator = "creator"
        case userUid = "userUid"
    }
    
    var creator: [String: Any] = [
        "id": "",
        "name": ""
    ]
    
//    let db = Firestore.firestore()
    var dataBase = Firestore.firestore()
    var dbModels: [[String: Any]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
//    var postId: String
    
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        bgView.layer.cornerRadius = 25
        fetchCommetData()
    }
    
    @IBAction func sendComment(_ sender: Any) {
        if commentTextField.text == "" {
            let alert = UIAlertController(title: "錯誤", message: "請輸入內容", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確認", style: .default))
            self.present(alert, animated: true)
        } else {
            addCommend(text: commentTextField.text ?? "")
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func closePopVC(_ sender: Any) {
        dismiss(animated: true)
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
            Comments.userUid.rawValue: userData?.id
            
//            Comments.postId.rawValue: postId
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
//        db.collection("Comments").order(by: Comments.time.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
            self?.dbModels = []
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    self?.dbModels.insert(document.data(), at: 0)
                }
            }
        }
    }
    
    func listen() {
        dataBase.collection("Adoption").addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            snapshot.documentChanges.forEach { diff in
                if (diff.type == .added) {
                }
            }
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
        
        UserFirebaseManager.shared.fetchUser(userId: "\(firebaseData[Comments.userUid.rawValue] ?? "")") { result in
            switch result {
            case let .success(user):
                self.userData = user
                let url = self.userData?.imageURLString
                cell.commentUserImage.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.commentUserId.text = self.userData?.name
            case .failure(_):
                print("Error")
            }
        }
        return cell
    }
}
