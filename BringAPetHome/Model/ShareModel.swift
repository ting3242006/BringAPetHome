//
//  ShareModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import Foundation
import FirebaseFirestore

struct ShareModel: Codable {
//    static func == (lhs: ShareModel, rhs: ShareModel) -> Bool {
//        return lhs.createdTime < rhs.createdTime
//    }
//    static func < (lhs: ShareModel, rhs: ShareModel) -> Bool {
//        return lhs.createdTime < rhs.createdTime
//    }
    
    var shareContent: String
    var shareImageUrl: String
    var postId: String
//    var user: User
    var createdTime: Timestamp
//    var comments: ShareComment
//    var userName: String
    var userUid: String
}

struct ShareComment: Codable {
    var commentId: String
//    var userId: String
//    var userName: String
    var time: Date
    var text: String
    var userUid: String
}

struct User: Codable {
    var id: String
    var name: String
}
