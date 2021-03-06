//
//  ViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/14.
//

import UIKit
import Kingfisher
import Lottie
import MJRefresh

// 頁面狀態
enum PageStatus {
    case loadingMore
    case notLoadingMore
}

class HomeViewController: UIViewController {
    
    let header = MJRefreshStateHeader()
    var newAnimalList: [AnimalData] = []
    var skip: Int = 100
    var pageStatus: PageStatus = .notLoadingMore
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
        collectionView.allowsSelection = true
        
        // style
        collectionView.backgroundColor = UIColor(red: 244/255, green: 247/255, blue: 245/255, alpha: 1)
        collectionView.showsVerticalScrollIndicator = false
        
        // layout
        view.addSubview(collectionView)
        collectionView.fillSuperView()
        collectionView.register(HomeCollectionViewCell.self,
                                forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier)
        
        fetchData()
        setupMJRefresh()
        setupNavigationItem()
        updateNavBarColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        updateNavBarColor()
    }
    
    @objc func headerRefresh() {
        // 更新資料
        fetchData()
        self.collectionView.reloadData()
        // 结束刷新
        self.collectionView.mj_header?.endRefreshing()
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
    
    private func fetchData() {
        self.setupLottie()
        ShelterManager.shared.fetchData(skip: skip) { [weak self] result in
            switch result {
            case .success(let animalDatas):
                self?.animalDatas = animalDatas
                // 把沒照片的排到後面
                self?.animalDatas = animalDatas.filter({ $0.albumFile != ""
                })
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func setupNavigationItem() {
        if let image = UIImage(systemName: "waveform.and.magnifyingglass") {
            let resizeImage = resizeImage(image: image, width: 30)
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: resizeImage.withRenderingMode(.alwaysOriginal).withTintColor(UIColor.darkGray ).withRenderingMode(.alwaysOriginal),
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(didTap))
        }
    }
    
    private func updateNavBarColor() {
            if #available(iOS 15.0, *) {
                let barAppearance = UINavigationBarAppearance()
                barAppearance.configureWithOpaqueBackground()
                barAppearance.backgroundColor = UIColor(named: "CulturedWhite")
                        navigationController?.navigationBar.standardAppearance = barAppearance
                navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
                navigationController?.navigationBar.compactAppearance = barAppearance
                navigationController?.navigationBar.compactScrollEdgeAppearance = barAppearance
            } else {
                navigationController?.navigationBar.barTintColor = UIColor(named: "CulturedWhite")
            }
        }
    
    private func setupLottie() {
        let animationView = AnimationView(name: "lf30_editor_wgvv5jrs")
        animationView.frame = CGRect(x: 0, y: 0, width: 150, height: 120)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        
        view.addSubview(animationView)
        animationView.play(fromFrame: 0, toFrame: 288, loopMode: .playOnce, completion: { (finished) in
            animationView.isHidden = true
        })
    }
    
    private func resizeImage(image: UIImage, width: CGFloat) -> UIImage {
        let size = CGSize(width: width, height:
                            image.size.height * width / image.size.width)
        let renderer = UIGraphicsImageRenderer(size: size)
        let newImage = renderer.image { (context) in
            image.draw(in: renderer.format.bounds)
        }
        return newImage
    }
    
    private func setupMJRefresh() {
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        header.frame = CGRect(x: 0, y: 0, width: 80, height: 50)
        self.collectionView.mj_header = header
    }
    
    // MARK: - Action
    @objc private func didTap() {
        let filterVC = UIStoryboard(name: "Main",
                                    bundle: nil).instantiateViewController(
                                        withIdentifier: "HomeFilterViewController") as? HomeFilterViewController
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
            return animalDatas.count
        } else {
            return newAnimalList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? HomeCollectionViewCell
        else { return UICollectionViewCell() }
        let item = self.animalDatas[indexPath.item]
        let url = item.albumFile
        cell.shelterImageView.kf.setImage(with: URL(string: url), placeholder: UIImage(named: "dketch-4"))
        cell.shelterImageView.contentMode = .scaleAspectFill
        cell.shelterImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cell.layer.cornerRadius = 10
        cell.shelterImageView.clipsToBounds = true
        cell.sexLabel.text = ShelterManager.shared.sexCh(sex: item.sex)
        cell.sexLabel.textColor = UIColor(named: "RichBlack")
        cell.placeLabel.textColor = UIColor(named: "RichBlack")
        cell.placeLabel.text = ShelterManager.shared.areaName(pkid: item.areaPkid)
        var name = ""
        switch cell.sexLabel.text {
        case "男":
            name = "BOY-1"
        case "女":
            name = "GIRL-1"
        default:
            name = "paws"
        }
        cell.sexImageView.image = UIImage(named: name)
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 5)
        cell.layer.shadowRadius = 3
        cell.layer.shadowOpacity = 0.3

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
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.skip += 100
                print("skip = \(self.skip)")
                self.fetchData()
                self.newAnimalList.append(contentsOf: self.animalDatas)
                self.pageStatus = .notLoadingMore
                self.collectionView.reloadData()
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
        self.setupLottie()
        ShelterManager.shared.fetchData(skip: 0, filter: filter) { [weak self]
            result in
            
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
