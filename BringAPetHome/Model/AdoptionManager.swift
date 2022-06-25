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
    
    static let shared = AdoptionManager()
    
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
    
    var comment = [
        "commentId": "",
        "userId": ""
    ]
    
    enum Comment: String {
//        case commentContent = ""
        case commentId = "commentId"
//        case time = ""
        case userId = ""
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
    
    //    struct UploadData: Codable {
    //        let age: Age
    //        let sex: Sex
    //        let petable: Petable
    //    }
    
    enum Age: Int {
        case threeMonthOld
        case sixMonthOld
        case oneYearOld
        case biggerThanOneYear
        
        var ageString: String {
            switch self {
            case .threeMonthOld:
                return "三個月內"
            case .sixMonthOld:
                return "六個月內"
            case .oneYearOld:
                return "六個月到一年"
            case .biggerThanOneYear:
                return "一歲以上"
            default:
                return ""
            }
        }
    }
    
    enum Sex: Int {
        case boy
        case girl
        
        var sexString: String {
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
    
    enum Petable: Int {
        case adopt = 0
        case adopted = 1
        
        var petable: String {
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
    
    //    static let shared = AdoptionManager()
    var dataBase = Firestore.firestore() // 初始化 Firestore
    let adoptionFirebaseModel = AdoptionModel()
    
    func addAdoption(age: Int, content: String, imageFileUrl: String,
                     location: String, sex: Int, petable: Int, commentId: String, postId: String) {
        
        let adoptions = Firestore.firestore().collection("Adoption")
        let document = adoptions.document()
        let data: [String: Any] = [
            Adoption.age.rawValue: age,
            Adoption.comment.rawValue: comment,
            Adoption.content.rawValue: content,
            Adoption.postId.rawValue: document.documentID,
            Adoption.createdTime.rawValue: NSDate().timeIntervalSince1970,
            //            Adoption.sendId.rawValue: document.documentID,
            Adoption.imageFileUrl.rawValue: imageFileUrl,
            Adoption.location.rawValue: location,
            Adoption.petable.rawValue: petable,
            Comment.commentId.rawValue: commentId,
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
