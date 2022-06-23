//
//  CommentViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/23.
//

import UIKit
import Firebase

class CommentViewController: UIViewController {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var dataBase = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        bgView.layer.cornerRadius = 25
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func closePopVC(_ sender: Any) {
        self.tabBarController?.tabBar.isHidden = false
        dismiss(animated: true)
    }
    
    func sendComment() {
        
    }
    
    func listen() {
        dataBase.collection("Adoption").addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            snapshot.documentChanges.forEach { diff in
                if (diff.type == .added) {
//                    print("New artical: \(diff.document.documentID), \(diff.document.data())")
                }
            }
        }
    }
}

extension CommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell",
                                                       for: indexPath) as? CommentTableViewCell else { return UITableViewCell() }
        cell.commentUserImage.image = UIImage(named: "cat_ref")
        
        return cell
    }
}
