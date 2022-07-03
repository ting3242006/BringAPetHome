//
//  ShareManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class ShareManager {
    
    var dataBase = Firestore.firestore()
    static let shared = ShareManager()
    var shareList = [ShareModel]()
    var postId: String?
    var dbModels: [[String: Any]] = []
    var commentList = [ShareComment]()
    //    {
    //        didSet {
    //            tableView.reloadData()
    //        }
    //    }
    
    func addSharing(uid: String, shareContent: String, image: String) {
        let share = dataBase.collection("Share")
        let document = share.document()
        let postId = document.documentID
        let timeInterval = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        let dates = formatter.string(from: timeInterval)
        
        let data: [String: Any] = [
            "user": [
                "id": "ting",
                "name": Auth.auth().currentUser?.displayName],
            "postId": "\(postId)",
            "image": image,
            "createdTime": timeInterval,
            "shareContent": shareContent,
            "userUid": Auth.auth().currentUser?.uid
//            "userUid": uid
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error\(error)")
            } else {
                print("Sharing update!")
            }
        }
    }
    
    func fetchSharing(completion: @escaping ([ShareModel]?) -> Void) {
        dataBase.collection("Share").order(by: "createdTime", descending: true).getDocuments { (querySnapshot, _) in
            guard let querySnapshot = querySnapshot else {
                return
            }
            self.shareList.removeAll()
            for document in querySnapshot.documents {
                let shareObject = document.data(with: ServerTimestampBehavior.none)
                let shareTime = shareObject["createdTime"] as? Int ?? 0
                let shareImage = shareObject["image"] as? String ?? ""
                let sharePostId = shareObject["postId"] as? String ?? ""
                let shareContent = shareObject["shareContent"] as? String ?? ""
                
                let share = ShareModel(shareContent: shareContent, shareImageUrl: shareImage,
                                       postId: sharePostId, createdTime: shareTime)
                self.shareList.append(share)
            }
            completion(self.shareList)
        }
    }
    
    func addComments(uid: String, postId: String, comments: String) {
        let comment = dataBase.collection("ShareComment")
        let document = comment.document()
        let timeInterval = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        let dates = formatter.string(from: timeInterval)
        
        let data: [String: Any] = [
            "user": [
                "id": "ting3242006",
                "name": Auth.auth().currentUser?.displayName],
//            "comments": [
//                "commentId": document.documentID,
//                "text": "\(comments)"],
            "commentId": document.documentID,
            "text": "\(comments)",
            "time": timeInterval,
            "postId": postId,
            "userUid": Auth.auth().currentUser?.uid
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error\(error)")
            } else {
                print("Comment update!")
            }
        }
    }
    
    func fetchSharingComment(postId: String ,completion: @escaping(Result<[ShareComment]>) -> Void) {
        dataBase.collection("ShareComment").whereField("postId", isEqualTo: postId ?? "").getDocuments { (querySnapshot, error) in
            if let error = error {
                print(LocalizedError.self)
                completion(.failure(error))
            } else {
                var shareComments = [ShareComment]()
                for document in querySnapshot!.documents {
                    do {
                        print(document)
                        if let shareComment = try document.data(as: ShareComment?.self,
                           decoder: Firestore.Decoder()) {
                            shareComments.append(shareComment)
                        }
                        print("55555\(shareComments)")
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(shareComments))
            }
        }
    }
    
//    func fetchSharingComment(completion: @escaping ([ShareComment]?) -> Void) {
//        dataBase.collection("ShareComment").whereField("postId", isEqualTo: postId ?? "").getDocuments() { [weak self] (querySnapshot, error) in
//            guard let querySnapshot = querySnapshot else {
//                return
//            }
////            self?.dbModels = []
//            self?.commentList.removeAll()
//            for document in querySnapshot.documents {
//                let sharingComment = document.data(with: ServerTimestampBehavior.none)
//                let commentTime = sharingComment["time"] as? Int ?? 0
//                let commentPostId = sharingComment["postId"] as? String ?? ""
//                let commentContent = sharingComment["text"] as? String ?? ""
//                let userId = sharingComment["userUid"] as? Int ?? 0
//                let comment = ShareComment(commentId: commentPostId, time: commentTime, text: commentContent, userId: userUid)
//                self?.commentList.append(comment)
//            }
//            completion(self?.commentList)
//            print("======\(self?.commentList)")
////            if let error = error {
////                print("Error fetching documents: \(error)")
////            } else {
////                for document in querySnapshot!.documents {
////                    self?.dbModels.insert(document.data(), at: 0)
////                    print("============\(document.data())")
////                }
////            }
//        }
//    }
    
    func fetchUserSharing(uid: String, completion: @escaping ([ShareModel]?) -> Void) {
        dataBase.collection("Share").whereField("userUid", isEqualTo: uid).order(by: "createdTime", descending: true).getDocuments { (querySnapshot, _) in
//        dataBase.collection("Share").whereField("userUid", isEqualTo: uid).getDocuments { (querySnapshot, _) in
            guard let querySnapshot = querySnapshot else {
                return
            }
            self.shareList.removeAll()
            for document in querySnapshot.documents {
                let shareObject = document.data(with: ServerTimestampBehavior.none)
                let shareTime = shareObject["createdTime"] as? Int ?? 0
                let shareImage = shareObject["image"] as? String ?? ""
                let sharePostId = shareObject["postId"] as? String ?? ""
                let shareContent = shareObject["shareContent"] as? String ?? ""
                
                let share = ShareModel(shareContent: shareContent, shareImageUrl: shareImage,
                                       postId: sharePostId, createdTime: shareTime)
                self.shareList.append(share)
            }
            completion(self.shareList)
        }
    }
}
