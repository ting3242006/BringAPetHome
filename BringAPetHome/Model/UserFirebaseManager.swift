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

class UserFirebaseManager {
    
    static let shared = UserFirebaseManager()
    private let dataBase = Firestore.firestore()
    var currentUser: UserModel?
    var userData: UserModel?
    
    func addUser(name: String, uid: String, email: String, image: String) {
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
            "image": image
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
                let userImage = userData["userImage"] as? String ?? ""
                let user = UserModel(id: userId, name: userName, email: userEmail, imageURLString: userImage)
                self.userData = user
            }
            completion(.success(self.userData ?? UserModel(id: "", name: "", email: "", imageURLString: "")))
        }
    }
    
    func updateUserInfo(id: String, image: String, name: String, completion: @escaping (Result<Void>) -> Void) {
        let docRef = dataBase.collection("User").document(id).updateData([
            "name": name,
            "image": image
        ])
        completion(.success(()))
    }
    
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
}
