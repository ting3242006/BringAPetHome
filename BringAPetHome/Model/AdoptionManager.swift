//
//  AdoptionManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class AdoptionManager {
    
    static let shared = AdoptionManager()
    let database = Firestore.firestore()
    let adoptionFirebaseModel = AdoptionModel()
    var comment = [
        "commentId": "",
        "userId": ""
    ]
    var dbModels: [[String: Any]] = []
    var refreshControl: UIRefreshControl!
    
    func addAdoption(age: Int, content: String, imageFileUrl: String,
                     location: String, sex: Int, commentId: String,
                     postId: String, userId: String) {
        print("addAdoption")
        let adoptions = Firestore.firestore().collection("Adoption")
        let document = adoptions.document()
        let data: [String: Any] = [
            Adoption.age.rawValue: age,
            Adoption.comment.rawValue: comment,
            Adoption.content.rawValue: content,
            Adoption.postId.rawValue: document.documentID,
            Adoption.createdTime.rawValue: NSDate().timeIntervalSince1970,
            Adoption.imageFileUrl.rawValue: imageFileUrl,
            Adoption.location.rawValue: location,
            Comment.commentId.rawValue: commentId,
            Adoption.sex.rawValue: sex,
            Adoption.userId.rawValue: userId
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error\(error)")
            } else {
                print("Document update")
            }
        }
    }
    
    func fetchAdoption(uid: String, completion: @escaping ([[String: Any]]?) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            database.collection("User").document(uid).getDocument { snapshot, error in
                guard let snapshot = snapshot,
                      snapshot.exists,
                      let userModel = try? snapshot.data(as: UserModel.self) else {
                    return
                }
                self.database.collection("Adoption").whereField("userId", notIn: userModel.blockedUser).order(by: "userId")
                    .order(by: Adoption.createdTime.rawValue).getDocuments() { [weak self] (querySnapshot, error) in
                        self?.dbModels = []
                        if let error = error {
                            print("Error fetching documents: \(error)")
                        } else {
                            print("querySnapshot!.documents", querySnapshot!.documents.count)
                            for document in querySnapshot!.documents {
                                self?.dbModels.insert(document.data(), at: 0)
                                self?.dbModels.sort {
                                    let time0Number = $0["createdTime"] as? Double ?? 0.0
                                    let time0 = Date(timeIntervalSince1970: time0Number)
                                    let time1Number = $1["createdTime"] as? Double ?? 0.0
                                    let time1 = Date(timeIntervalSince1970: time1Number)
                                    return time0 > time1
                                }
                            }
                            completion(self?.dbModels)
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
                        self?.dbModels.insert(document.data(), at: 0)
                        document.data()
                    }
                    completion(self?.dbModels)
                }
            }
        }
    }
}
