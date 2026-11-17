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
