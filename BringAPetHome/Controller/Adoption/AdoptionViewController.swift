//
//  AdoptionViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit
import Firebase

enum Age: Int, Codable {
    case threeMonthOld = 0
    case sixMonthOld
    case oneYearOld
    case biggerThanOneYear
    
    var title: String {
        switch self {
        case .threeMonthOld:
            return "三個月內"
        case .sixMonthOld:
            return "六個月內"
        case .oneYearOld:
            return "六個月到一年"
        case .biggerThanOneYear:
            return "一歲以上"
        }
    }
}

enum Sex: Int, Codable {
    case boy = 0
    case girl = 1
    
    var sexTitle: String {
        switch self {
        case .boy:
            return "男"
        case .girl:
            return "女"
        default:
            return ""
        }
    }
}

enum Petable: Int, Codable {
    case adopt = 0
    case adopted = 1
    
    var petableTitle: String {
        switch self {
        case .adopt:
            return "送養"
        case .adopted:
            return "已領養"
        default:
            return ""
        }
    }
}

public var isUserBlocked: Bool = false

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
    var adoptionFirebaseModel = AdoptionModel()
    var userData: UserModel?
    var adoptionList = [AdoptionModel]()
    
    enum Adoption: String {
        case age = "age"
        case comment = "comment"
        case content = "content"
        case userId = "userId"
        case createdTime = "createdTime"
        case sendId = "sendId"
        case imageFileUrl = "imageFileUrl"
        case location = "location"
        case petable = "petable"
        case sex = "sex"
        case postId = "postId"
    }
    
    enum Comment: String {
        case commentId = "commentId"
        case commentContent = "commentContent"
        case time = "time"
        case userId = "userId"
    }
    
    enum Comments: String {
        case commentText = "commentText"
        case commentId = "commentId"
        case time = "time"
        case creator = "creator"
    }
    
    var creator: [String: Any] = [
        "id": "",
        "name": ""
    ]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference().child("Adoption")
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
        selectedBackgroundView.backgroundColor = UIColor.clear
        navigationController?.navigationBar.backgroundColor = .clear
        setButtonLayout()
        fetchData()
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
//        refresh()
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
    
    func setButtonLayout() {
        view.addSubview(publishButton)
        publishButton.backgroundColor = UIColor(named: "HoneyYellow")
        //        publishButton.layer.masksToBounds = true
        publishButton.layer.cornerRadius = 30
        publishButton.tintColor = .white
        publishButton.setImage(UIImage(systemName: "plus"), for: .normal)
        publishButton.layer.shadowOpacity = 0.75
        publishButton.layer.shadowOffset = .zero
        publishButton.layer.shadowRadius = 8
        publishButton.layer.shadowPath = UIBezierPath(roundedRect: publishButton.bounds,
                                                      cornerRadius: publishButton.layer.cornerRadius).cgPath
        publishButton.layer.shadowColor = UIColor.darkGray.cgColor
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
        if let uid = Auth.auth().currentUser?.uid {
            database.collection("User").document(uid).getDocument { snapshot, error in
                guard let snapshot = snapshot,
                      snapshot.exists,
                      let userModel = try? snapshot.data(as: UserModel.self) else {
                    return
                }
                print("userModel.blockedUser", userModel.blockedUser)
                self.database.collection("Adoption").whereField("userId", notIn: userModel.blockedUser).order(by: "userId")
                    .order(by: Adoption.createdTime.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
                        self?.dbModels = []
                        if let error = error {
                            print("Error fetching documents: \(error)")
                        } else {
                            print("querySnapshot!.documents", querySnapshot!.documents.count)
                            for document in querySnapshot!.documents {
                                self?.dbModels.insert(document.data(), at: 0)
                                print("============\(document.data())")
                                self?.dbModels.sort {
                                    let time0Number = $0["createdTime"] as? Double ?? 0.0
                                    let time0 = Date(timeIntervalSince1970: time0Number)
                                    let time1Number = $1["createdTime"] as? Double ?? 0.0
                                    let time1 = Date(timeIntervalSince1970: time1Number)
                                    return time0 > time1
                                }
                            }
                            self?.refreshControl!.endRefreshing()
                        }
                    }
            }
        } else {
            self.database.collection("Adoption").order(by: Adoption.createdTime.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
                self?.dbModels = []
                if let error = error {
                    print("Error fetching documents: \(error)")
                } else {
                    print("querySnapshot!.documents", querySnapshot!.documents.count)
                    for document in querySnapshot!.documents {
                        //                    self?.userData.
                        self?.dbModels.insert(document.data(), at: 0)
                        print("============\(document.data())")
                    }
                }
                self?.refreshControl!.endRefreshing()
            }
        }
    }
    
    func refresh() {
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(fetchData), for: UIControl.Event.valueChanged)
    }
    
    func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        //self.navigationController?.present(loginVC, animated: true)
        present(loginVC, animated: true)
    }
    
    @IBSegueAction func showComments(_ coder: NSCoder, sender: Any?) -> CommentViewController? {
        let controller = CommentViewController(coder: coder)
        let button = sender as? UIButton
        if let point = button?.convert(CGPoint.zero, to: tableView),
           let indexPath = tableView.indexPathForRow(at: point) {
            let firebaseData = dbModels[indexPath.row]
            controller?.adoptionId = firebaseData[Adoption.postId.rawValue] as? String ?? ""
            //            controller.userData?.blockedUser = firebaseData[User[blockedUser].rawValue] as [String] ?? ""
            tabBarController?.tabBar.isHidden = true
        }
        return controller
    }
    
    func confirmBlocked(userId: String) {
        let alert  = UIAlertController(title: "封鎖用戶", message: "確認要封鎖此用戶嗎? 封鎖後將看不到此用戶貼文", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "確認", style: .destructive) { (_) in
            self.database.collection("User").document(Auth.auth().currentUser?.uid ?? "").updateData(["blockedUser": FieldValue.arrayUnion([userId])])
            self.fetchData()
            self.tableView.reloadData()
        }
        let noAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func checkBlockedUser() {
        if isUserBlocked == true {
            return
        } else {
            
        }
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
        //        let postId = firebaseData[Adoption.postId.rawValue] as? [String: Any] ?? [:]
        let commentId = firebaseData[Comments.commentId.rawValue] as? [String: Any] ?? [:]
        let date = NSDate(timeIntervalSince1970: createdTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        
        cell.layout(location: "\(firebaseData[Adoption.location.rawValue] ?? "")",
                    date: "刊登日期：\(formatter.string(from: date as Date))",
                    content: "\(firebaseData[Adoption.content.rawValue] ?? "")",
                    imageFileUrl: "\(firebaseData[Adoption.imageFileUrl.rawValue] ?? "")", age: age ?? .threeMonthOld, sex: sex ?? .boy, petable: petable ?? .adopt)
        var name = ""
        switch cell.adoptionSexLabel.text {
        case "男":
            name = "BOY-1"
        case "女":
            name = "GIRL-1"
        default:
            name = "paws"
        }
        cell.sexIconImage.image = UIImage(named: name)
        
        if let petable = firebaseData[Adoption.petable.rawValue] as? Int {
            cell.setupPetable(petable: petable)
        }
        
        //        UserFirebaseManager.shared.fetchUser(userId: "\(firebaseData[Adoption.userId.rawValue] ?? "")")
        //        UserFirebaseManager.shared.fetchUser(userId: Auth.auth().currentUser?.uid ?? "")
        //        UserFirebaseManager.shared.fetchUser(userId: Auth.auth().currentUser?.uid ?? "") { result in
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
