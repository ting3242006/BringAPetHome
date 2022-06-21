//
//  AdoptionFirebaseModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/20.
//

import Foundation

class AdoptionFirebaseModel {
    
    enum Adoption: String {
        case age = "age"
        case comment = "comment"
        case content = "content"
        case giverId = "giverId"
        case createdTime = "createdTime"
        case sendId = "sendId"
        case imageFileUrl = "imageFileUrl"
        case location = "location"
        case petable = "petable"
        case sex = "sex"
    }
    
    enum Comment: String {
        case commentContent = "commentContent"
        case commentId = "commentId"
        case time = "time"
        case userId = "userId"
    }
}
