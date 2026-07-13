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
    let areaPkid: Int
    let animalSterilization: String
    let title: String
    let cDate: String
    let albumUpdate: String

    enum CodingKeys: String, CodingKey {
        case animalId = "animal_id"
        case place = "animal_place"
        case kind = "animal_kind"
        case areaPkid = "animal_area_pkid"
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
        case animalSterilization = "animal_sterilization"
        case title = "animal_title"
        case cDate = "cDate"
        case albumUpdate = "album_update"
    }
}

struct AnimalDeepLink {
    private static let scheme = "bringapethome"
    private static let animalHost = "animal"
    private static let snapshotQueryName = "snapshot"

    struct Route {
        let animalId: Int
        let animal: AnimalData?
    }

    static func url(for animalId: Int) -> URL? {
        URL(string: "\(scheme)://\(animalHost)/\(animalId)")
    }

    static func url(for animal: AnimalData) -> URL? {
        guard let data = try? JSONEncoder().encode(animal) else { return nil }

        var components = URLComponents()
        components.scheme = scheme
        components.host = animalHost
        components.path = "/\(animal.animalId)"
        components.queryItems = [
            URLQueryItem(name: snapshotQueryName, value: urlSafeBase64(from: data))
        ]
        return components.url
    }

    static func animalId(from url: URL) -> Int? {
        route(from: url)?.animalId
    }

    static func route(from url: URL) -> Route? {
        guard url.scheme == scheme,
              url.host == animalHost,
              let animalIdText = url.pathComponents.dropFirst().first,
              let animalId = Int(animalIdText)
        else { return nil }

        let snapshot = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == snapshotQueryName })?
            .value
        let animal = snapshot.flatMap(animal(from:))
        return Route(animalId: animalId, animal: animal?.animalId == animalId ? animal : nil)
    }

    private static func urlSafeBase64(from data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func animal(from snapshot: String) -> AnimalData? {
        var base64 = snapshot
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let missingPadding = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: missingPadding))

        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(AnimalData.self, from: data)
    }
}

struct AnimalShareContentBuilder {
    static func activityItems(for animal: AnimalData) -> [Any] {
        let message = message(for: animal)
        guard let deepLink = AnimalDeepLink.url(for: animal) else { return [message] }

        return [message, deepLink]
    }

    static func message(for animal: AnimalData) -> String {
        let bodytype = ShelterManager.shared.bodytypeCh(bodytype: animal.bodytype)
        let variety = animal.animalVariety
        let bodytypeAndVariety = "\(bodytype)\(variety)"
        let deepLink = AnimalDeepLink.url(for: animal)?.absoluteString ?? ""

        let lines = [
            "我在 Bring A Pet Home 看到一隻正在等待認養的\(animal.kind)",
            "性別：\(ShelterManager.shared.sexCh(sex: animal.sex))",
            "年齡：\(ShelterManager.shared.ageCh(age: animal.age))",
            "體型/品種：\(bodytypeAndVariety)",
            "毛色：\(animal.colour)",
            "收容所：\(animal.shelterName)",
            "電話：\(animal.shelterTel)",
            "地址：\(animal.shelterAddress)",
            "開放認養：\(animal.opendate)",
            "查看詳細資料：\(deepLink)"
        ]

        return lines.joined(separator: "\n")
    }
}
