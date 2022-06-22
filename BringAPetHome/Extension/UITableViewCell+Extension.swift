//
//  UITableViewCell.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/15.
//

import UIKit

extension UITableViewCell {
    static var identifier: String {
        return String(describing: self)
    }
}
extension UITableViewHeaderFooterView {
    static var identifier: String {
        return String(describing: self)
    }
}
extension UICollectionReusableView {
    static var identifier: String {
        return String(describing: self)
    }
}
