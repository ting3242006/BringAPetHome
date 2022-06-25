////
////  ShareViewController.swift
////  BringAPetHome
////
////  Created by Ting on 2022/6/24.
////
//
//import UIKit
//
//class ShareViewController: UIViewController {
//    
//    static let reuseIdentifier = "\(ShareCollectionViewCell.self)"
//
//    @IBOutlet weak var collectionView: UICollectionView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
//        flowLayout?.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
//        configureCellSize()
//    }
//
//    func configureCellSize() {
//            let itemSpace: Double = 4
//            let columnCount: Double = 3
//            let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
//            let width = floor((collectionView.bounds.width - itemSpace * (columnCount-1)) / columnCount)
//            flowLayout?.itemSize = CGSize(width: width, height: width)
//            flowLayout?.estimatedItemSize = .zero
//            flowLayout?.minimumInteritemSpacing = itemSpace
//            flowLayout?.minimumLineSpacing = itemSpace
//
//    }
//}
//
//extension ShareViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        6
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShareCollectionViewCell.reuseIdentifier, for: indexPath) as? ShareCollectionViewCell
//        else { return UICollectionViewCell() }
//    }
//}
