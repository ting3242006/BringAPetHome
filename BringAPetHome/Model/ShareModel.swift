//
//  ShareModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import Foundation

struct ShareModel: Comparable, Codable {
    static func == (lhs: ShareModel, rhs: ShareModel) -> Bool {
        return lhs.createdTime < rhs.createdTime
    }
    static func < (lhs: ShareModel, rhs: ShareModel) -> Bool {
        return lhs.createdTime < rhs.createdTime
    }
    
    var shareContent: String
    var shareImageUrl: String
    var postId: String
//    var user: User
    var createdTime: Int
//    var comment: ShareComment
//    var userName: String
}

struct ShareComment: Codable {
    var commentId: String
    var userId: String
    var userName: String
    var time: Int
    var text: String
}

struct User: Codable {
    var id: String
    var name: String
}
