//
//  BringAPetHomeTests.swift
//  BringAPetHomeTests
//
//  Created by Ting on 2022/7/20.
//

import XCTest
@testable import BringAPetHome

class BringAPetHomeTests: XCTestCase {
    
    var sut: URLSession!
    var shelterManager: ShelterManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = URLSession(configuration: .default)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testApiCallCompletes() throws {
          // given
          let urlString = "https://data.coa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL"
          let url = URL(string: urlString)!
          let promise = expectation(description: "Completion handler invoked")
          var statusCode: Int?
          var responseError: Error?

          // when
          let dataTask = sut.dataTask(with: url) { _, response, error in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
          }
          dataTask.resume()
          wait(for: [promise], timeout: 5)

          // then
          XCTAssertNil(responseError)
          XCTAssertEqual(statusCode, 200)
        }
    
    // decoder API 能不能裝進 shelterDataModel 裡面
    // 或檢查 API 跟專案裡的有沒有一樣
    
    func testApiStatusCode() throws {
        let url = URL(string: "https://data.coa.gov.tw/Service/OpenData/TransService.aspx?UnitId=QcbUEzN6E6DL")!
        let promise = expectation(description: "Status code: 200")
        
        sut.dataTask(with: url) { (data, response, error) in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
                return
            }
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode == 200 {
                    promise.fulfill()
                } else {
                    XCTFail("Status Code: \(statusCode)")
                }
            }
        }.resume()
        wait(for: [promise], timeout: 5)
    }
    
    func checkApiIsSame() {
        
    }
}
