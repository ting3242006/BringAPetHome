//
//  ShelterDataModel.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import Foundation



struct AnimalData: Codable {
    
    let animalId: Int
    let place: String
    let kind: String
    let sex: String
    let bodytype: String
    let colour: String
    let age: String
    let status: String
    let remark: String
    let opendate: String
    let shelterName: String
    let albumFile: String
    let shelterAddress: String
    let shelterTel: String
    let animalVariety: String
    
    enum CodingKeys: String, CodingKey {
        case animalId = "animal_id"
        case place = "animal_place"
        case kind = "animal_kind"
        case sex = "animal_sex"
        case bodytype = "animal_bodytype"
        case colour = "animal_colour"
        case age = "animal_age"
        case status = "animal_status"
        case remark = "animal_remark"
        case opendate = "animal_opendate"
        case shelterName = "shelter_name"
        case albumFile = "album_file"
        case shelterAddress = "shelter_address"
        case shelterTel = "shelter_tel"
        case animalVariety = "animal_Variety"
    }
}
