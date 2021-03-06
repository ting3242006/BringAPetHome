//
//  ShelterManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import Foundation
import MapKit

// swiftlint:enable identifier_name

class ShelterManager {
    
    static let shared = ShelterManager()
    
    private init() { }
    
    func fetchData(skip: Int, filter: Filter? = nil, completion: @escaping (Result<[AnimalData]>) -> Void) {
        
        var urlString = "https://data.coa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL&$top=1000&$skip=\(skip)"
        if let filter = filter {
            if let kind = filter.kind {
                urlString.append("&animal_kind=\(kind)")
            }
            if let sex = filter.sex {
                urlString.append("&animal_sex=\(sex)")
            }
            if let bodytype = filter.bodytype {
                urlString.append("&animal_bodytype=\(bodytype)")
            }
        }
            
        guard let urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            do {
                let animalDatas = try JSONDecoder().decode([AnimalData].self, from: data)
                completion(.success(animalDatas))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    // 拉回 mainThread
    
    // swiftlint:disable all
    func areaName(pkid: Int) -> String {
        switch pkid {
        case 2:
            return  "台北市"
        case 3:
            return  "新北市"
        case 4:
            return  "基隆市"
        case 5:
            return  "宜蘭縣"
        case 6:
            return  "桃園縣"
        case 7:
            return  "新竹縣"
        case 8:
            return  "新竹市"
        case 9:
            return  "苗栗縣"
        case 10:
            return  "臺中市"
        case 11:
            return  "彰化縣"
        case 12:
            return  "南投縣"
        case 13:
            return  "雲林縣"
        case 14:
            return  "嘉義縣"
        case 15:
            return  "嘉義市"
        case 16:
            return  "臺南市"
        case 17:
            return  "高雄市"
        case 18:
            return  "屏東縣"
        case 19:
            return  "花蓮縣"
        case 20:
            return  "臺東縣"
        case 21:
            return  "澎湖縣"
        case 22:
            return  "金門縣"
        case 23:
            return  "連江縣"
        default:
            return ""
        }
    }
    // swiftlint:ensable all
    
    func sexCh(sex: String) -> String {
        switch sex {
        case "M":
            return "男"
        case "F":
            return "女"
        case "N":
            return "未輸入"
        default:
            return ""
        }
    }
    
    func ageCh(age: String) -> String {
        switch age {
        case "CHILD":
            return "幼年"
        case "ADULT":
            return "成年"
        case "F":
            return "不詳"
        default:
            return "不詳"
        }
    }
    
    func bodytypeCh(bodytype: String) -> String {
        switch bodytype {
        case "SMALL":
            return "小型"
        case "MEDIUM":
            return "中型"
        case "BIG":
            return "大型"
        default:
            return ""
        }
    }
    
    func sterilization(sterilization: String) -> String {
        switch sterilization {
        case "T":
            return "已絕育"
        case "F":
            return "未絕育"
        case "N":
            return "未確認"
        default:
            return ""
        }
    }
    
    func status(status: String) -> String {
        switch status {
        case "OPEN":
            return "開放領養"
        default:
            return ""
        }
    }
}
