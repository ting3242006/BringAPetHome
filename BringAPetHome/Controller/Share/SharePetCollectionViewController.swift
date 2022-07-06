//
//  SharePetCollectionViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/25.
//

import UIKit
import Firebase

class SharePetCollectionViewController: UICollectionViewController {
    
    var shareManager = ShareManager()
    var shareList = [ShareModel]()
    var publishButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonLayout()
        configureCellSize()
        //        guard let userData = userData else {
        //            return
        //        }

        shareManager.fetchSharing(completion: { shareList in
            self.shareList = shareList ?? []
            self.collectionView.reloadData()
        })
    }
    //    guard let userData = userData else {
    //        return
    //    }
    override func viewDidAppear(_ animated: Bool) {
        shareManager.fetchSharing(completion: { shareList in self.shareList = shareList ?? []
            self.collectionView.reloadData()
        })
    }
    
    @IBAction func goSharingPost(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postSharingVC = mainStoryboard.instantiateViewController(withIdentifier: "PostSharingViewController") as? PostSharingViewController else { return }
        self.navigationController?.pushViewController(postSharingVC, animated: true)
    }
    
    func setButtonLayout() {
        view.addSubview(publishButton)
        publishButton.backgroundColor = UIColor(named: "HoneyYellow")
        //        publishButton.layer.masksToBounds = true
        publishButton.layer.cornerRadius = 30
        publishButton.tintColor = .white
        publishButton.setImage(UIImage(systemName: "plus"), for: .normal)
        publishButton.layer.shadowOpacity = 0.75
        publishButton.layer.shadowOffset = .zero
        publishButton.layer.shadowRadius = 8
        publishButton.layer.shadowPath = UIBezierPath(roundedRect: publishButton.bounds,
                                                      cornerRadius: publishButton.layer.cornerRadius).cgPath
        publishButton.layer.shadowColor = UIColor.darkGray.cgColor
        publishButton.addTarget(self, action: #selector(didTapped), for: .touchUpInside)
        publishButton.anchor(bottom: view.bottomAnchor,
                             trailing: view.trailingAnchor,
                             padding: .init(top: 0, left: 0, bottom: 95, right: 20),
                             width: 60, height: 60)
    }
    
    @objc func didTapped() {
        if Auth.auth().currentUser == nil {
            showLoginVC()
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postSharingVC = mainStoryboard.instantiateViewController(withIdentifier: "PostSharingViewController") as? PostSharingViewController else { return }
        self.navigationController?.pushViewController(postSharingVC, animated: true)
    }
    
    func showLoginVC() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "SignInWithAppleVC") as? SignInWithAppleVC else { return }
        present(loginVC, animated: true)
    }
    
    func configureCellSize() {
        // cell and cell spacing
        let itemSpace: Double = 3
        // How many colume in a row
        let columnCount: Double = 3
        // 將 collectionViewLayout 轉型成 UICollectionViewFlowLayout (向下捲動)
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        // 計算 cell 寬度，利用畫面的寬減去要的間距然後再除以要拆分成幾格
        let width = floor((collectionView.bounds.width - itemSpace * (columnCount-1)) / columnCount)
        // 設定cell的大小
        flowLayout?.itemSize = CGSize(width: width, height: width)
        // 設成 zero 才會根據 itemSize 來設定 cell 大小，不然會被 autoLayout 條件影響(如果有額外設定 cell autoLayout)
        flowLayout?.estimatedItemSize = .zero
        // 定義 cell 間的間距(左右間距)
        flowLayout?.minimumInteritemSpacing = itemSpace
        // 定義 colume 間的間距(上下間距)
        flowLayout?.minimumLineSpacing = itemSpace
        // 定義 cell 到邊框間的間距(上下左右)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        shareList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShareCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? ShareCollectionViewCell else { return UICollectionViewCell() }
        let urls = shareList[indexPath.row].shareImageUrl
        cell.shareImage.kf.setImage(with: URL(string: urls), placeholder: UIImage(named: "dketch-4"))
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = mainStoryboard.instantiateViewController(withIdentifier: "ShareDetailViewController") as? ShareDetailViewController else { return }
        let share = shareList[indexPath.item]
        detailVC.shareItem = share
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}
