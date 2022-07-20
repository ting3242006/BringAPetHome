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
    
    static let shared = ShareManager()
    var dataBase = Firestore.firestore()
    var shareList = [ShareModel]()
    var postId: String?
    var dbModels: [[String: Any]] = []
    var commentList = [ShareComment]()
    
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
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error\(error)")
            } else {
                print("Sharing update!")
            }
        }
    }
    
    // swiftlint:disable all
    func fetchSharing(completion: @escaping ([ShareModel]?) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            dataBase.collection("User").document(uid).getDocument { snapshot, error in
                guard let snapshot = snapshot,
                      snapshot.exists,
                      let userModel = try? snapshot.data(as: UserModel.self) else {
                    return
                }
                
                self.dataBase.collection("Share").whereField("userUid", notIn: userModel.blockedUser).order(by: "userUid").order(by: "createdTime", descending: true).getDocuments() { [weak self] (querySnapshot, error) in

                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    self?.shareList.removeAll()
                    for document in querySnapshot.documents {
                        let shareObject = document.data(with: ServerTimestampBehavior.none)
                        guard let shareTime = shareObject["createdTime"] as? Timestamp else { return }
                        let shareImage = shareObject["image"] as? String ?? ""
                        let sharePostId = shareObject["postId"] as? String ?? ""
                        let shareContent = shareObject["shareContent"] as? String ?? ""
                        let shareUserUid = shareObject["userUid"] as? String ?? ""
                        
                        let share = ShareModel(shareContent: shareContent,
                                               shareImageUrl: shareImage,
                                               postId: sharePostId,
                                               createdTime: shareTime,
                                               userUid: shareUserUid)
                        
                        self?.shareList.append(share)
                    }
                    completion(self?.shareList)
                }
            }
        } else {
            dataBase.collection("Share").order(by: "createdTime", descending: true).getDocuments { (querySnapshot, _) in
                guard let querySnapshot = querySnapshot else {
                    return
                }
                self.shareList.removeAll()
                for document in querySnapshot.documents {
                    let shareObject = document.data(with: ServerTimestampBehavior.none)
                    guard let shareTime = shareObject["createdTime"] as? Timestamp else { return }
                    let shareImage = shareObject["image"] as? String ?? ""
                    let sharePostId = shareObject["postId"] as? String ?? ""
                    let shareContent = shareObject["shareContent"] as? String ?? ""
                    let shareUserUid = shareObject["userUid"] as? String ?? ""
                    
                    let share = ShareModel(shareContent: shareContent, shareImageUrl: shareImage,
                                           postId: sharePostId, createdTime: shareTime, userUid: shareUserUid)
                    self.shareList.append(share)
                }
                completion(self.shareList)
            }
        }
    }
    // swiftlint:ensable all
    
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
    
    func fetchSharingComment(postId: String, completion: @escaping(Result<[ShareComment]>) -> Void) {
        print("postId", postId)
        dataBase.collection("ShareComment").whereField("postId", isEqualTo: postId).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("fetchSharingComment", LocalizedError.self)
                completion(.failure(error))
            } else {
                print("fetchSharingComment", querySnapshot!.documents.count)
                
                guard let snapshot = querySnapshot else { return }
                let shareComments: [ShareComment] = snapshot.documents.compactMap { snapshot in
                    do {
                        let comment = try snapshot.data(as: ShareComment.self)
                        return comment
                    } catch {
                        print(error)
                        return  nil
                    }
                }
                completion(.success(shareComments))
            }
        }
    }
    
    func fetchUserSharing(uid: String, completion: @escaping ([ShareModel]?) -> Void) {
        dataBase.collection("Share").whereField("userUid", isEqualTo: uid).order(by: "createdTime", descending: true).getDocuments { (querySnapshot, _) in
            //        dataBase.collection("Share").whereField("userUid", isEqualTo: uid).getDocuments { (querySnapshot, _) in
            guard let querySnapshot = querySnapshot else {
                return
            }
            self.shareList.removeAll()
            for document in querySnapshot.documents {
                let shareObject = document.data(with: ServerTimestampBehavior.none)
                guard let shareTime = shareObject["createdTime"] as? Timestamp else { return }
                let shareImage = shareObject["image"] as? String ?? ""
                let sharePostId = shareObject["postId"] as? String ?? ""
                let shareContent = shareObject["shareContent"] as? String ?? ""
                let shareUserUid = shareObject["userUid"] as? String ?? ""
                
                let share = ShareModel(shareContent: shareContent, shareImageUrl: shareImage,
                                       postId: sharePostId, createdTime: shareTime, userUid: shareUserUid)
                self.shareList.append(share)
            }
            completion(self.shareList)
        }
    }
}
