//
//  ProfileViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/27.
//

import UIKit
import FirebaseAuth
import Kingfisher

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
        getUserProfile()
        shareManager.fetchUserSharing(uid: userUid, completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
        userImageView.layer.cornerRadius = 50
        userImageView.layer.borderWidth = 3
        userImageView.layer.borderColor = UIColor.lightGray.cgColor
        userNameLabel.textAlignment = .center
//        userImageView.layer.borderColor = UIColor(named: "DavysGrey")?.cgColor
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
                userUid = ""
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
    
    override func viewWillAppear(_ animated: Bool) {
        getUserProfile()
//        UserFirebaseManager.shared.fetchUser(userId: userUid) { result in
        UserFirebaseManager.shared.fetchUser(userId: Auth.auth().currentUser?.uid ?? "") { result in
            switch result {
            case let .success(user):
                self.userData = user
                print("~~~~~\(self.userData)")
                self.userIdLabel.text = self.userData?.email
                self.userIdLabel.textColor = .lightGray
            case .failure(_):
                print("Error")
            }
        }
        shareManager.fetchUserSharing(uid: Auth.auth().currentUser?.uid ?? "", completion: { shareList in self.shareList = shareList ?? []
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
    
    func getUserProfile() {
        UserFirebaseManager.shared.fetchUser(userId: Auth.auth().currentUser?.uid ?? "") { result in
            switch result {
            case let .success(user):
                self.userData = user
                print("~~~~~\(self.userData)")
                let urls = self.userData?.imageURLString
                self.userImageView.kf.setImage(with: URL(string: urls ?? ""), placeholder: UIImage(named: "dketch-4"))
                self.userNameLabel.text = self.userData?.name
            case .failure(_):
                print("Error")
            }
        }
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
        
        // 陰影跑不出來
        cell.profileImageView.layer.shadowColor = UIColor.darkGray.cgColor
        cell.profileImageView.layer.shadowOffset = CGSize(width: 3, height: 3)
        cell.profileImageView.layer.shadowRadius = 3
        cell.profileImageView.layer.shadowOpacity = 0.5
        cell.profileImageView.layer.masksToBounds = false
        let urls = shareList[indexPath.row].shareImageUrl
        cell.profileImageView.kf.setImage(with: URL(string: urls), placeholder: UIImage(named: "dketch-4"))
        cell.profileContent.text = shareList[indexPath.row].shareContent
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
}
