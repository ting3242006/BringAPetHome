//
//  ImageUploader.swift
//  BringAPetHome
//

import Foundation
import FirebaseStorage

struct ImageUploader {

    /// 上傳 data 到 Storage 根目錄下的 `path`，成功後回傳 downloadURL。callback 與 Firebase 原 callback 同一執行緒層級。
    func upload(data: Data, path: String, completion: @escaping (Swift.Result<URL, Error>) -> Void) {
        let fileReference = Storage.storage().reference().child(path)
        fileReference.putData(data, metadata: nil) { result in
            switch result {
            case .success:
                fileReference.downloadURL { result in
                    completion(result)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
