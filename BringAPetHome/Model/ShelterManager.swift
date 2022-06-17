//
//  ShelterManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import Foundation

class ShelterManager {
    
    static let shared = ShelterManager()
    
    private init() { }
    
//    var skip: Int = 100
    
    func fetchData(skip: Int?, completion: @escaping (Result<[AnimalData]>) -> Void) {
        let urlString =  "https://data.coa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL&$top=100&$skip=\(skip)"
        
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
}
