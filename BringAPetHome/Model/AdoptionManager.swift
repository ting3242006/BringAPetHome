//
//  AdoptionManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/21.
//

import Foundation
import Firebase
import FirebaseFirestore

class AdoptionManager {
    
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
    
    var comment: [String: Any] = [
        "commentContent": "",
        "commentId": "",
        "time": 0,
        "userId": ""
    ]
    
    static let shared = AdoptionManager()
    var dataBase = Firestore.firestore() // 初始化 Firestore
    let adoptionFirebaseModel = AdoptionFirebaseModel()

    func addAdoption(age: Int, content: String, imageFileUrl: String,
                     location: String, sex: Int, petable: Int) {
        
        let adoptions = Firestore.firestore().collection("Adoption")
        let document = adoptions.document()
        let data: [String: Any] = [
            Adoption.age.rawValue: age,
            Adoption.comment.rawValue: comment,
            Adoption.content.rawValue: content,
            Adoption.userId.rawValue: document.documentID,
            Adoption.createdTime.rawValue: NSDate().timeIntervalSince1970,
            //            Adoption.sendId.rawValue: document.documentID,
            Adoption.imageFileUrl.rawValue: imageFileUrl,
            Adoption.location.rawValue: location,
            Adoption.petable.rawValue: petable,
            Adoption.sex.rawValue: sex
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error\(error)")
            } else {
                print("Document update")
            }
        }
    }
}
