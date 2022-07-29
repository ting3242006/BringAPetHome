//
//  ShareModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import Foundation
import FirebaseFirestore

struct ShareModel: Codable {    
    var shareContent: String
    var shareImageUrl: String
    var postId: String
    var createdTime: Timestamp
    var userUid: String
}

struct ShareComment: Codable {
    var commentId: String
    var time: Date
    var text: String
    var userUid: String
}
