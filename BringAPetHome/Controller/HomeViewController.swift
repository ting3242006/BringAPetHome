//
//  ViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/14.
//

import UIKit

class HomeViewController: UIViewController {
    
    var animalDatas = [AnimalData]() {
        didSet {
            reloadData()
        }
    }
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup
      
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // style
        collectionView.backgroundColor = .gray
        collectionView.showsVerticalScrollIndicator = false
        
        // layout
        view.addSubview(collectionView)
        collectionView.fillSuperView()
        
        collectionView.register(HomeCollectionViewCell.self,
                                forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier)
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true // 初始畫面不要顯示 NavigationBar
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false // 下一頁出現 NavigationBar
    }
    
    private func reloadData() {
        guard Thread.isMainThread == true else {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
            return
        }
        collectionView.reloadData()
    }
    
    func fetchData() {
        ShelterManager.shared.fetchData() { [weak self] result in
            switch result {
            case .success(let animalDatas):
                self?.animalDatas = animalDatas
                print("=======\(animalDatas)")
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        10
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier, for: indexPath) as? HomeCollectionViewCell
        else { return UICollectionViewCell() }
//        guard let data = animalDatas[indexPath.section] as? AnimalData else { return }
        cell.shelterImageView.image = UIImage(named: "cat_ref")
        cell.shelterImageView.contentMode = .scaleAspectFill
        cell.shelterImageView.layer.cornerRadius = 10
        cell.shelterImageView.clipsToBounds = true
        cell.sexLabel.text = "M"
        cell.placeLabel.text = "New Taipei City"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        //  跳到 detail 頁面
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (collectionView.bounds.width - 32 - 15) / 2
        let cellHeight = cellWidth * 1.85
        
        return CGSize(width: cellWidth, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
    }
}
