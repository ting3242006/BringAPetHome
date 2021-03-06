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
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var logoutBarButton: UIBarButtonItem!
    
    let selectedBackgroundView = UIView()
    var userData: UserModel?
    var shareList = [ShareModel]()
    var shareManager = ShareManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        selectedBackgroundView.backgroundColor = UIColor.clear
        checkUserLogin()
    }
    
    override func viewWillLayoutSubviews() {
        userImageView.layer.cornerRadius = 50
        userImageView.clipsToBounds = true
        userImageView.layer.borderWidth = 4
        userImageView.layer.borderColor = UIColor.white.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getUserProfile()
        shareManager.fetchUserSharing(uid: Auth.auth().currentUser?.uid ?? "", completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
        if Auth.auth().currentUser == nil {
            showLoginVC()
            userNameLabel.text = "暱稱"
            logoutBarButton.tintColor = UIColor.clear
            logoutBarButton.isEnabled = false
        } else {
            logoutBarButton.tintColor = nil
            logoutBarButton.isEnabled = true
            return
        }
    }
    
    @IBAction func editProfileInfo(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        } else {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let editVC = mainStoryboard.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController else { return }
            self.navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    @IBAction func logOutButton(_ sender: Any) {
        let controller = UIAlertController(title: "登出提醒", message: "確定要登出嗎?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "確定", style: .default) { _ in
            do {
                try Auth.auth().signOut()
                
                self.view.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController")
            } catch let signOutError as NSError {
                print("Error signing out: (signOutError)")
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(okAction)
        controller.addAction(cancelAction)
        present(controller, animated: true, completion: nil)
    }
    
    private func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        self.navigationController?.present(loginVC, animated: true)
    }
    
    private func getUserProfile() {
        if Auth.auth().currentUser != nil {
            UserFirebaseManager.shared.fetchUser(userId: Auth.auth().currentUser?.uid ?? "") { result in
                switch result {
                case let .success(user):
                    self.userData = user
                    let urls = self.userData?.image
                    self.userImageView.kf.setImage(with: URL(string: urls ?? ""))
                    self.userNameLabel.text = self.userData?.name
                case .failure(_):
                    print("Error")
                }
            }
        } else {
            userNameLabel.text = "暱稱"
        }
    }
    
    private func checkUserLogin() {
        if Auth.auth().currentUser == nil {
            showLoginVC()
        } else {
            return
        }
        let userUid = Auth.auth().currentUser?.uid ?? ""
        shareManager.fetchUserSharing(uid: userUid, completion: { shareList in self.shareList = shareList ?? []
            self.tableView.reloadData()
        })
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let shareDetailVC = mainStoryboard.instantiateViewController(withIdentifier: "ShareDetailViewController") as? ShareDetailViewController else {
            return
        }
        let share = shareList[indexPath.row]
        shareDetailVC.shareItem = share
        self.navigationController?.pushViewController(shareDetailVC, animated: true)
    }
}
