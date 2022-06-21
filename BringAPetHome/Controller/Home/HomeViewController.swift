//
//  ViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/14.
//

import UIKit
import Kingfisher

// 頁面狀態
enum PageStatus {
    case loadingMore
    case notLoadingMore
}

class HomeViewController: UIViewController {
    
    var animalDatas = [AnimalData]() {
        didSet {
            reloadData()
        }
    }
    
    var newAnimalList: [AnimalData] = []
    var skip: Int = 100
    var pageStatus: PageStatus = .notLoadingMore
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(systemName: "waveform.and.magnifyingglass") {
            let resizeImage = resizeImage(image: image, width: 30)
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: resizeImage.withRenderingMode(.alwaysOriginal).withTintColor(UIColor.darkGray ?? .orange).withRenderingMode(.alwaysOriginal),
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(didTap))
        }
        // setup
        collectionView.delegate = self
        collectionView.dataSource = self
        //        collectionView.isPagingEnabled = true
        collectionView.allowsSelection = true
        
        // style
        collectionView.backgroundColor = .lightGray
        collectionView.showsVerticalScrollIndicator = false
        
        // layout
        view.addSubview(collectionView)
        collectionView.fillSuperView()
        
        collectionView.register(HomeCollectionViewCell.self,
                                forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier)
        
        fetchData()
    }
    
    //    override func viewWillAppear(_ animated: Bool) {
    //        navigationController?.isNavigationBarHidden = true // 初始畫面不要顯示 NavigationBar
    //    }
    //
    //    override func viewWillDisappear(_ animated: Bool) {
    //        navigationController?.isNavigationBarHidden = false // 下一頁出現 NavigationBar
    //    }
    
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
        ShelterManager.shared.fetchData(skip: skip) { [weak self] result in
            switch result {
            case .success(let animalDatas):
                self?.animalDatas = animalDatas
                // 把沒照片的排到後面
                self?.animalDatas = animalDatas.filter({ $0.albumFile != ""
                })
                //                self?.newAnimalList = self!.newAnimalList.filter({ $0.albumFile != ""
                //                })
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
        let size = CGSize(width: width, height:
                            image.size.height * width / image.size.width)
        let renderer = UIGraphicsImageRenderer(size: size)
        let newImage = renderer.image { (context) in
            image.draw(in: renderer.format.bounds)
        }
        return newImage
    }
    
    // MARK: - Action
    @objc private func didTap() {
        let filterVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeFilterViewController") as? HomeFilterViewController
        filterVC?.delegate = self
        navigationController?.pushViewController(filterVC!, animated: true)
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if newAnimalList.isEmpty {
            //            print(":)))\(animalDatas.count)")
            return animalDatas.count
            
        } else {
            //            print("~~~\(newAnimalList.count)")
            return newAnimalList.count
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier, for: indexPath) as? HomeCollectionViewCell
        else { return UICollectionViewCell() }
        DispatchQueue.main.async {
            let item = self.animalDatas[indexPath.item]
            let url = item.albumFile
            cell.shelterImageView.kf.setImage(with: URL(string: url), placeholder: UIImage(named: "dketch-4"))
            cell.shelterImageView.contentMode = .scaleAspectFill
            cell.shelterImageView.layer.cornerRadius = 10
            cell.shelterImageView.clipsToBounds = true
            cell.sexLabel.text = String(item.sex)
            cell.placeLabel.text = item.place
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeDetailViewController") as? HomeDetailViewController else { return }
        let pet = animalDatas[indexPath.item]
        detailVC.pet = pet
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView.contentSize.height > self.collectionView.frame.height,
              self.pageStatus == .notLoadingMore else { return }
        if scrollView.contentSize.height - (scrollView.frame.size.height + scrollView.contentOffset.y) <= -10 {
            self.pageStatus = .loadingMore
            //            self.collectionView.reloadData {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.skip += 100
                print("skip = \(self.skip)")
                self.fetchData()
                self.newAnimalList.append(contentsOf: self.animalDatas)
                self.pageStatus = .notLoadingMore
                //                self.collectionView.reloadData()
                //                }
            }
        }
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

extension HomeViewController: HomeFilterViewControllerDelegate {
    func selectFilterViewController(_ controller: HomeFilterViewController, didSelect filter: Filter) {
        
        ShelterManager.shared.fetchData(skip: 0, filter: filter) { [weak self] result  in
            switch result {
            case .success(let animalDatas):
                self?.animalDatas = animalDatas
                // 把沒照片的排到後面
                self?.animalDatas = animalDatas.filter({ $0.albumFile != ""
                })
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
