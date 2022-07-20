//
//  AdoptionFirebaseModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/20.
//

import Foundation

class AdoptionModel {
    
//    enum Adoption: String {
//        case age = "age"
//        case comment = "comment"
//        case content = "content"
//        case giverId = "giverId"
//        case createdTime = "createdTime"
//        case sendId = "sendId"
//        case imageFileUrl = "imageFileUrl"
//        case location = "location"
//        case petable = "petable"
//        case sex = "sex"
//    }
//
//    enum Comment: String {
//        case commentContent = "commentContent"
//        case commentId = "commentId"
//        case time = "time"
//        case userId = "userId"
//    }

}

enum Age: Int, Codable {
    case threeMonthOld = 0
    case sixMonthOld
    case oneYearOld
    case biggerThanOneYear
    
    var title: String {
        switch self {
        case .threeMonthOld:
            return "三個月內"
        case .sixMonthOld:
            return "六個月內"
        case .oneYearOld:
            return "六個月到一年"
        case .biggerThanOneYear:
            return "一歲以上"
        }
    }
}

enum Sex: Int, Codable {
    case boy = 0
    case girl = 1
    
    var sexTitle: String {
        switch self {
        case .boy:
            return "男"
        case .girl:
            return "女"
        }
    }
}

enum Petable: Int, Codable {
    case adopt = 0
    case adopted = 1
    
    var petableTitle: String {
        switch self {
        case .adopt:
            return "送養"
        case .adopted:
            return "已領養"
        }
    }
}

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

enum Comment: String {
    case commentId = "commentId"
    case commentContent = "commentContent"
    case time = "time"
    case userId = "userId"
}

enum Comments: String {
    case commentText = "commentText"
    case commentId = "commentId"
    case time = "time"
    case creator = "creator"
}
