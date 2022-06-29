//
//  ProfileViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/27.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var coverImageView: UIImageView!
    
    var gradient = CAGradientLayer()
    let selectedBackgroundView = UIView()
    var userData: UserModel?
    var shareList = [ShareModel]()
    var shareManager = ShareManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedBackgroundView.backgroundColor = UIColor.clear
        setCoverImageGradient()
        tableView.dataSource = self
        tableView.delegate = self
        //        tableView.backgroundColor = .orange
        showLoginVC()
        shareManager.fetchUserSharing(uid: userUid, completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
        userImageView.layer.cornerRadius = 40
//        userImageView.layer.bounds = true
    }
    
    @IBAction func editProfileInfo(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let editVC = mainStoryboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController else { return }
        self.navigationController?.pushViewController(editVC, animated: true)
    }
        
    @IBAction func logOutButton(_ sender: Any) {
        let controller = UIAlertController(title: "登出提醒", message: "確定要登出嗎?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "確定", style: .default) { _ in
            do {
                try Auth.auth().signOut()
//                self.navigationController?.popToRootViewController(animated: true)
//                self.tableView.reloadData()
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
                self.navigationController?.pushViewController(homeVC, animated: true)
                print("sign out")
            } catch let signOutError as NSError {
               print("Error signing out: (signOutError)")
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(okAction)
        controller.addAction(cancelAction)
        present(controller, animated: true, completion: nil)
    }
  
//        do {
//            try Auth.auth().signOut()
//            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
//            self.navigationController?.pushViewController(homeVC, animated: true)
//        } catch {
//            print(error)
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        UserFirebaseManager.shared.fetchUser(userId: userUid) { result in
            switch result {
            case let .success(user):
                self.userData = user
                print("~~~~~\(self.userData)")
                self.userIdLabel.text = self.userData?.email
                self.userIdLabel.textColor = .white
            case .failure(_):
                print("Error")
            }
        }
        shareManager.fetchUserSharing(uid: userUid, completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
//        showLoginVC()
        if Auth.auth().currentUser == nil {
            showLoginVC()
//            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
//            self.navigationController?.pushViewController(loginVC, animated: true)
        } else {
            return
        }
    }
    
    func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    func setCoverImageGradient() {
        gradient.frame = coverImageView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.2).cgColor]
        gradient.locations = [1, 0.2, 0]
        coverImageView.layer.addSublayer(gradient)
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shareList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell",
                                                       for: indexPath) as? ProfileTableViewCell else {
            return UITableViewCell()
        }
        let urls = shareList[indexPath.row].shareImageUrl
        cell.profileImageView.kf.setImage(with: URL(string: urls), placeholder: UIImage(named: "dketch-4"))
        cell.profileContent.text = shareList[indexPath.row].shareContent
        cell.selectedBackgroundView = selectedBackgroundView
        return cell
    }
}
