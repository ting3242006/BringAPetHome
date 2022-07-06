//
//  UserModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/28.
//

import Foundation

struct UserModel: Codable {
    
    var id: String
    var name: String
    var email: String
    var imageURLString: String
    var blockedUser: [String]
}
