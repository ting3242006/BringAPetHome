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
    var dbModels: [[String: Any]] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
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
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        
        return cell
    }
}
