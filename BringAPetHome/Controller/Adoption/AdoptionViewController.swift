//
//  AdoptionViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/19.
//

import UIKit
import Firebase

class AdoptionViewController: UIViewController {
    
    let db = Firestore.firestore()
    var databaseRef: DatabaseReference!
    var dbModels: [[String: Any]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var adoptionFirebaseModel = AdoptionModel()
    
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
    }
    
    enum Comment: String {
        case commentId = "commentId"
        case commentContent = "commentContent"
        case time = "time"
        case userId = "userId"
    }
    
    struct DownloadData: Codable {
        let age: Age
        let sex: Sex
        let petable: Petable
    }
    
    enum Age: String, Codable {
        case threeMonthOld = "三個月內"
        case sixMonthOld = "六個月內"
        case oneYearOld = "六個月到一年"
        case biggerThanOneYear = "一歲以上"
        
        var ageInt: Int {
            switch self {
            case .threeMonthOld:
                return 0
            case .sixMonthOld:
                return 1
            case .oneYearOld:
                return 2
            case .biggerThanOneYear:
                return 3
            default:
                return 0
            }
        }
    }
    
    enum Sex: String, Codable {
        case boy = "Boy"
        case girl = "Girl"
        
        var sexInt: Int {
            switch self {
            case .boy:
                return 0
            case .girl:
                return 1
            default:
                return 0
            }
        }
    }
    
    enum Petable: String, Codable {
        case adopt = "送養"
        case adopted = "已領養"
        
        var petableInt: Int {
            switch self {
            case .adopt:
                return 0
            case .adopted:
                return 1
            default:
                return 0
            }
        }
    }
    var showSex: String?
    var showAge: String?
    var showPetable: String?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference().child("Adoption")
        tableView.dataSource = self
        tableView.delegate = self
        fetchData()
        tableView.reloadData()
    }
    
    @IBAction func addAdoptionArticles(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let publishAdoptionViewController = mainStoryboard.instantiateViewController(withIdentifier: "PublishAdoptionViewController") as? PublishAdoptionViewController else { return }
        self.navigationController?.pushViewController(publishAdoptionViewController, animated: true)
    }
    
    func fetchData() {
        db.collection("Adoption").order(by: Adoption.createdTime.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
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
}

extension AdoptionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dbModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AdoptionTableViewCell", for: indexPath) as? AdoptionTableViewCell
        else { return UITableViewCell()
        }
        let firebaseData = dbModels[indexPath.row]
        let comment: [String: Any] = firebaseData[Adoption.comment.rawValue] as? [String: Any] ?? [:]
        let createdTime = firebaseData[Adoption.createdTime.rawValue] as? Double ?? 0.0
        let petable = firebaseData[Adoption.petable.rawValue] as? Double ?? 0.0
        let age = firebaseData[Adoption.age.rawValue] as? Double ?? 0.0
        let sex = firebaseData[Adoption.sex.rawValue] as? Double ?? 0.0
        let adoptionAnimalImage = firebaseData[Adoption.imageFileUrl.rawValue] as? [String: Any] ?? [:]
        let date = NSDate(timeIntervalSince1970: createdTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        
        cell.layout(location: "\(firebaseData[Adoption.location.rawValue] ?? "")",
                    date: formatter.string(from: date as Date),
                    content: "\(firebaseData[Adoption.content.rawValue] ?? "")",
                    imageFileUrl: "\(firebaseData[Adoption.imageFileUrl.rawValue] ?? "")")
        //    petable: "\(firebaseData[Adoption.petable.rawValue] ?? "")"),
        //    age: "\(firebaseData[Adoption.age.rawValue] ?? "")"),
        //    sex: "\(firebaseData[Adoption.sex.rawValue] ?? "")")
//        cell.petableLabel.text = "\(String(describing: firebaseData[Adoption.petable.rawValue]))" ?? ""
//        let petable = showPetable
        if let petable = firebaseData[Adoption.petable.rawValue] as? Int {
            cell.setupPetable(petable: petable)
        }
        
//        cell.setupAge(age: "\(firebaseData[Adoption.age.rawValue])")
//        cell.setupSex(sex: firebaseData[Adoption.age.rawValue])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
