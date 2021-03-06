//
//  AdoptionViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit
import Firebase

class AdoptionViewController: UIViewController {
    
    let database = Firestore.firestore()
    let selectedBackgroundView = UIView()
    var publishButton = UIButton()
    var refreshControl: UIRefreshControl!
    var databaseRef: DatabaseReference!
    var dbModels: [[String: Any]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var userData: UserModel?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference().child("Adoption")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        setButtonLayout()
        fetchData()
        refresh()
        layout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    @IBAction func addAdoptionArticles(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let publishAdoptionViewController = mainStoryboard.instantiateViewController(withIdentifier: "PublishAdoptionViewController") as? PublishAdoptionViewController else { return }
        self.navigationController?.pushViewController(publishAdoptionViewController, animated: true)
    }
    
    @IBSegueAction func showComments(_ coder: NSCoder, sender: Any?) -> CommentViewController? {
        let controller = CommentViewController(coder: coder)
        let button = sender as? UIButton
        if let point = button?.convert(CGPoint.zero, to: tableView),
           let indexPath = tableView.indexPathForRow(at: point) {
            let firebaseData = dbModels[indexPath.row]
            controller?.adoptionId = firebaseData[Adoption.postId.rawValue] as? String ?? ""
            tabBarController?.tabBar.isHidden = true
        }
        return controller
    }
    
    private func layout() {
        navigationController?.navigationBar.backgroundColor = .clear
        selectedBackgroundView.backgroundColor = UIColor.clear
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
    
    @objc func didTapped() {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let publishAdoptionViewController = mainStoryboard.instantiateViewController(withIdentifier: "PublishAdoptionViewController") as? PublishAdoptionViewController else { return }
        self.navigationController?.pushViewController(publishAdoptionViewController, animated: true)
    }
    
    @objc func fetchData() {
        AdoptionManager.shared.fetchAdoption(uid: Auth.auth().currentUser?.uid ?? "") { [weak self] dbModels in
            if let dbModels = dbModels {
                self?.dbModels = dbModels
                guard let refreshControl = self?.refreshControl else { return }
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    private func refresh() {
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(fetchData), for: UIControl.Event.valueChanged)
    }
    
    private func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        present(loginVC, animated: true)
    }
    
    private func confirmBlocked(userId: String) {
        let alert  = UIAlertController(title: "????????????", message: "???????????????????????????? ????????????????????????????????????", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "??????", style: .destructive) { (_) in
            self.database.collection("User").document(Auth.auth().currentUser?.uid ?? "").updateData(["blockedUser": FieldValue.arrayUnion([userId])])
            self.fetchData()
            self.tableView.reloadData()
        }
        let noAction = UIAlertAction(title: "??????", style: .cancel)
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        
        present(alert, animated: true, completion: nil)
    }
}

extension AdoptionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dbModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AdoptionTableViewCell",
                                                       for: indexPath) as? AdoptionTableViewCell
        else { return UITableViewCell()
        }
        cell.adoptionTableViewCellDelegate = self
        cell.selectedBackgroundView = selectedBackgroundView
        let firebaseData = dbModels[indexPath.row]
        let comment: [String: Any] = firebaseData[Adoption.comment.rawValue] as? [String: Any] ?? [:]
        let createdTime = firebaseData[Adoption.createdTime.rawValue] as? Double ?? 0.0
        let petable = Petable(rawValue: firebaseData[Adoption.petable.rawValue] as? Int ?? 0)
        let age = Age(rawValue: firebaseData[Adoption.age.rawValue] as? Int ?? 0)
        let sex = Sex(rawValue: firebaseData[Adoption.sex.rawValue] as? Int ?? 0)
        let adoptionAnimalImage = firebaseData[Adoption.imageFileUrl.rawValue] as? [String: Any] ?? [:]
        let date = NSDate(timeIntervalSince1970: createdTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        
        cell.layout(location: "\(firebaseData[Adoption.location.rawValue] ?? "")",
                    date: "???????????????\(formatter.string(from: date as Date))",
                    content: "\(firebaseData[Adoption.content.rawValue] ?? "")",
                    imageFileUrl: "\(firebaseData[Adoption.imageFileUrl.rawValue] ?? "")", age: age ?? .threeMonthOld, sex: sex ?? .boy, petable: petable ?? .adopt)
        var name = ""
        switch cell.adoptionSexLabel.text {
        case "???":
            name = "BOY-1"
        case "???":
            name = "GIRL-1"
        default:
            name = "paws"
        }
        cell.sexIconImage.image = UIImage(named: name)
        
        UserFirebaseManager.shared.fetchUser(userId: "\(firebaseData[Adoption.userId.rawValue] ?? "")") { result in
            switch result {
            case let .success(user):
                self.userData = user
                let url = self.userData?.image
                cell.userImageView.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.usernameLabel.text = self.userData?.name
            case .failure:
                print("Error")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension AdoptionViewController: AdoptionTableViewCellDelegate {
    func tappedBlock(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let firebaseData = dbModels[indexPath.row]
        self.confirmBlocked(userId: "\(firebaseData[Adoption.userId.rawValue] ?? "")")
    }
}
