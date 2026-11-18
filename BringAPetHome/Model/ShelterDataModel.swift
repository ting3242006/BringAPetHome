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
    private static let universalLinkHost = "bringapethome.web.app"
    private static let snapshotQueryName = "snapshot"

    struct Route {
        let animalId: Int
        let animal: AnimalData?
    }

    static func url(for animalId: Int) -> URL? {
        guard animalId > 0 else { return nil }
        return URL(string: "https://\(universalLinkHost)/animal/\(animalId)")
    }

    static func animalId(from url: URL) -> Int? {
        route(from: url)?.animalId
    }

    static func route(from url: URL) -> Route? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.user == nil, components.password == nil, components.port == nil
        else { return nil }

        let host = components.host?.lowercased()
        let isUniversalLink = components.scheme == "https" && host == universalLinkHost
        let isCustomLink = components.scheme == scheme && host == animalHost
        guard isUniversalLink || isCustomLink else { return nil }

        let prefix = isUniversalLink ? "/animal/" : "/"
        let path = components.percentEncodedPath
        guard path.hasPrefix(prefix) else { return nil }
        let animalIdText = String(path.dropFirst(prefix.count))
        guard let firstCharacter = animalIdText.utf8.first,
              (49...57).contains(firstCharacter),
              animalIdText.utf8.allSatisfy({ (48...57).contains($0) }),
              let animalId = Int(animalIdText)
        else { return nil }

        guard isCustomLink else { return Route(animalId: animalId, animal: nil) }
        let snapshot = components.queryItems?.first(where: { $0.name == snapshotQueryName })?.value
        let animal = snapshot.flatMap(animal(from:))
        return Route(animalId: animalId, animal: animal?.animalId == animalId ? animal : nil)
    }

    static func url(from userActivity: NSUserActivity) -> URL? {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              url.scheme == "https", route(from: url) != nil
        else { return nil }
        return url
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
        [message(for: animal)]
    }

    static func message(for animal: AnimalData) -> String {
        let bodytype = ShelterManager.shared.bodytypeCh(bodytype: animal.bodytype)
        let variety = animal.animalVariety
        let bodytypeAndVariety = "\(bodytype)\(variety)"
        var components = AnimalDeepLink.url(for: animal.animalId)
            .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        components?.queryItems = [URLQueryItem(name: "openExternalBrowser", value: "1")]
        let deepLink = components?.url?.absoluteString ?? ""

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

struct Filter: Equatable {
    var kind: String?
    var sex: String?
    var bodytype: String?
    var areaPkid: Int?
}
