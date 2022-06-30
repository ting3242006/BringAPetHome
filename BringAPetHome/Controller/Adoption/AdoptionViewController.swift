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
            return "Boy"
        case .girl:
            return "Girl"
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

class AdoptionViewController: UIViewController {
    
    let database = Firestore.firestore()
    var databaseRef: DatabaseReference!
    var dbModels: [[String: Any]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var adoptionFirebaseModel = AdoptionModel()
    let selectedBackgroundView = UIView()
    var userData: UserModel?
    
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
        fetchData()
        tableView.reloadData()
        selectedBackgroundView.backgroundColor = UIColor.clear
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    @IBAction func addAdoptionArticles(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let publishAdoptionViewController = mainStoryboard.instantiateViewController(withIdentifier: "PublishAdoptionViewController") as? PublishAdoptionViewController else { return }
        self.navigationController?.pushViewController(publishAdoptionViewController, animated: true)
    }
    
    func fetchData() {
        database.collection("Adoption").order(by: Adoption.createdTime.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
            self?.dbModels = []
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    self?.dbModels.insert(document.data(), at: 0)
                    print("============\(document.data())")
                }
            }
        }
    }
    
    @IBSegueAction func showComments(_ coder: NSCoder, sender: Any?) -> CommentViewController? {
        let controller = CommentViewController(coder: coder)
        let button = sender as? UIButton
        if let point = button?.convert(CGPoint.zero, to: tableView),
           let indexPath = tableView.indexPathForRow(at: point) {
            let firebaseData = dbModels[indexPath.row]
            controller?.adoptionId = firebaseData[Adoption.postId.rawValue] as? String ?? ""
        }
        return controller
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
                    date: formatter.string(from: date as Date),
                    content: "\(firebaseData[Adoption.content.rawValue] ?? "")",
                    imageFileUrl: "\(firebaseData[Adoption.imageFileUrl.rawValue] ?? "")", age: age ?? .threeMonthOld, sex: sex ?? .boy, petable: petable ?? .adopt)

        if let petable = firebaseData[Adoption.petable.rawValue] as? Int {
            cell.setupPetable(petable: petable)
        }
        
        UserFirebaseManager.shared.fetchUser(userId: Auth.auth().currentUser?.uid ?? "") { result in
            switch result {
            case let .success(user):
                self.userData = user
                let url = self.userData?.imageURLString
                cell.userImageView.kf.setImage(with: URL(string: url ?? ""), placeholder: UIImage(named: "dketch-4"))
                cell.usernameLabel.text = self.userData?.name
            case .failure(_):
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
