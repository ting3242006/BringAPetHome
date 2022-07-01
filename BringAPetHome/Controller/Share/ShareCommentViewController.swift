//
//  ShareCommentViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/27.
//

import UIKit

class ShareCommentViewController: UIViewController {
    
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var postId: String?
    var shareModel: ShareModel?
    
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
        tableView.dataSource = self
        tableView.delegate = self
//        ShareManager.shared.fetchSharing(completion: <#T##([ShareModel]?) -> Void#>)
    }
    @IBAction func closeView(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func sendShareComment(_ sender: Any) {
        ShareManager.shared.addComments(postId: shareModel?.postId ?? "", comments: commentTextField.text ?? "")
    }
}

extension ShareCommentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareCommentTableViewCell",
                                                       for: indexPath) as? ShareCommentTableViewCell else { return UITableViewCell() }
        cell.userImageView.image = UIImage(named: "dketch-4")
        
        return cell
    }
}
