//
//  ShelterManager.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import Foundation

class ShelterManager {
    
    static let shared = ShelterManager()
    
    private init() {}
    
    func fetchData(completion: @escaping (Result<[AnimalData]>) -> Void) {
        guard let urlString = URL(string: "https://data.coa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL") else { return }
        var request = URLRequest(url: urlString)
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
