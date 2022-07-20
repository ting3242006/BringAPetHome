//
//  UserFirebaseManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/28.
//

import Foundation
import FirebaseAuth
import Firebase
import AuthenticationServices
import FirebaseStorage
import CoreAudio
import CoreML

class UserFirebaseManager {
    
    static let shared = UserFirebaseManager()
    private let dataBase = Firestore.firestore()
    var currentUser: UserModel?
    var userData: UserModel?
    var friendData: UserModel?
    public var isUserBlocked: Bool = false
    
    func addUser(name: String, uid: String, email: String, image: String, blockedUser: [String]) {
        let user = dataBase.collection("User")
        let document = user.document(uid)
        let timeInterval = Date()
        //        let userId = document.documentID
        let data: [String: Any] = [
            "email": email,
            //            "auth": Auth.auth().currentUser?.displayName ?? "",
            "auth": currentUser,
            //            "auth": Auth.auth().currentUser?.displayName ?? "nil",
            "id": uid,
            "name": name,
            "createdTime": timeInterval,
            "image": image,
            "blockedUser": blockedUser
        ]
        document.setData(data) { error in
            if let error = error {
                print("Error(error)")
            } else {
                print("Document update!")
            }
        }
    }
    
    func fetchUser(userId: String, completion: @escaping (Result<UserModel>) -> Void) {
        dataBase.collection("User").whereField("id", isEqualTo: userId).getDocuments { querySnapshot, _ in
            guard let querySnapshot = querySnapshot else {
                return
            }
            for data in querySnapshot.documents {
                let userData = data.data(with: ServerTimestampBehavior.none)
                let userName = userData["name"] as? String ?? ""
                let userEmail = userData["email"] as? String ?? ""
                let userId = userData["id"] as? String ?? ""
                let userImage = userData["image"] as? String ?? ""
                let blockedUser = userData["blockedUser"] as? [String] ?? [""]
                let user = UserModel(id: userId, name: userName, email: userEmail, image: userImage, blockedUser: blockedUser)
                self.userData = user
            }
            completion(.success(self.userData ?? UserModel(id: "", name: "", email: "", image: "", blockedUser: [""])))
        }
    }
    
    func updateUserInfo(id: String, image: String, name: String, completion: @escaping (Result<Void>) -> Void) {
        let docRef = dataBase.collection("User").document(id).updateData([
            "name": name,
            "image": image
        ])
        completion(.success(()))
    }
    
    //    func fetchUserInfo(uid: String, completion: @escaping ([UserModel]?) -> Void) {
    //        dataBase.collection("User").whereField("id", isEqualTo: uid).getDocuments { (querySnapshot, _) in
    //            guard let querySnapshot = querySnapshot else {
    //                return
    //            }
    //            //            self.shareList.removeAll()
    //            for data in querySnapshot.documents {
    //                let userData = data.data(with: ServerTimestampBehavior.none)
    //                let userName = userData["name"] as? String ?? ""
    //                let userEmail = userData["email"] as? String ?? ""
    //                let userId = userData["id"] as? String ?? ""
    //                let userImage = userData["userImage"] as? String ?? ""
    //                let user = UserModel(id: userId, name: userName, email: userEmail, imageURLString: userImage)
    //                self.userData = user
    //            }
    //            completion(.success(self.userData ?? UserModel(id: "", name: "", email: "", imageURLString: "")))
    //        }
    //    }
    
    func deleteAccount() {
        let user = Auth.auth().currentUser
        user?.delete { error in
            if let error = error {
                // An error happened.
            } else {
                // Account deleted.
            }
        }
    }
    
    func checkUserEmail(userId: String, completion: @escaping (Result<UserModel>) -> Void) {
        print("checkUserEmail")
        dataBase.collection("User").whereField("id", isEqualTo: userId).getDocuments { querySnapshot, _ in
            print(querySnapshot, querySnapshot?.documents.count)
            if let querySnapshot = querySnapshot {
                if let document = querySnapshot.documents.first {
                    
                    for data in querySnapshot.documents {
                        let userData = data.data(with: ServerTimestampBehavior.none)
                        let userName = userData["name"] as? String ?? ""
                        let userEmail = userData["email"] as? String ?? ""
                        let userId = userData["id"] as? String ?? ""
                        let userImage = userData["image"] as? String ?? ""
                        let blockList = userData["blockedUser"] as? [String] ?? [""]
                        
                        let user = UserModel(id: userId, name: userName, email: userEmail, image: userImage, blockedUser: blockList)
                        self.friendData = user
                        let blockUser = user.blockedUser
                        self.isUserBlocked = blockUser.contains { (blockId) -> Bool in
                            blockId == self.friendData?.id
                        }
                    }
                    let blockList = self.userData?.blockedUser ?? []
                    self.isUserBlocked = blockList.contains { (blockId) -> Bool in
                        blockId == self.friendData?.id
                    }
                    if self.isUserBlocked == true {
                        let alertController = UIAlertController(
                            title: "找不到此用戶", message: "已經封鎖此用戶", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "確認", style: .cancel, handler: nil)
                        alertController.addAction(cancelAction)
                        alertController.present(alertController, animated: true)
                        
                    } else if self.isUserBlocked == false {
                        //                        self.confirm()
                    }
                }
                print("Account is exist")                
            } else {
                UserFirebaseManager.shared.addUser(name: "name",
                                                   uid: Auth.auth().currentUser?.uid ?? "",
                                                   email: Auth.auth().currentUser?.email ?? "",
                                                   image: "image", blockedUser: ["blockedUser"])
            }
        }
    }
}
