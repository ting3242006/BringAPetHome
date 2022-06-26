//
//  HTTP.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum STHTTPClientError: Error {
    case decodeDataFail
    case clientError(Data)
    case serverError
    case unexpectedError
}

enum STHTTPMethod: String {
    case GET
    case POST
}

enum STHTTPHeaderField: String {
    case contentType = "Content-Type"
    case auth = "Authorization"
}

enum STHTTPHeaderValue: String {
    case json = "application/json"
}

protocol STRequest {
    var headers: [String: String] { get }
    var body: Data? { get }
    var method: String { get }
    var endPoint: String { get }
}
