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
    private let thumbnailProcessor = DownsamplingImageProcessor(size: CGSize(width: 170, height: 150))
    private let initialPageSize = 20
    private let estimatedVisibleCellCount = 18
    private let pageSize = 50
    private var skip: Int = 0
    private var isFetching = false
    private var hasMoreData = true
    private var hasPrefetchedAfterInitialLoad = false
    private var currentFilter: Filter?
    private var imagePrefetchers: [ImagePrefetcher] = []
    private var delayedBackgroundFetch: DispatchWorkItem?
    private lazy var loadingAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "lf30_editor_wgvv5jrs")
        animationView.frame = CGRect(x: 0, y: 0, width: 150, height: 120)
        animationView.center = self.view.center
        animationView.contentMode = .scaleAspectFill
        animationView.isHidden = true
        return animationView
    }()
    var pageStatus: PageStatus = .notLoadingMore
    var animalDatas = [AnimalData]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.allowsSelection = true
        
        // style
        collectionView.backgroundColor = UIColor(red: 244/255, green: 247/255, blue: 245/255, alpha: 1)
        collectionView.showsVerticalScrollIndicator = false
        
        // layout
        view.addSubview(collectionView)
        collectionView.fillSuperView()
        collectionView.register(HomeCollectionViewCell.self,
                                forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier)
        
        view.addSubview(loadingAnimationView)
        fetchData(reset: true)
        setupMJRefresh()
        setupNavigationItem()
        updateNavBarColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        updateNavBarColor()
    }
    
    @objc func headerRefresh() {
        fetchData(reset: true) { [weak self] in
            self?.collectionView.mj_header?.endRefreshing()
        }
    }
    
    private func fetchData(reset: Bool = false, isBackgroundPrefetch: Bool = false, completion: (() -> Void)? = nil) {
        guard isFetching == false else {
            completion?()
            return
        }
        guard hasMoreData || reset else {
            completion?()
            return
        }

        if reset {
            skip = 0
            hasMoreData = true
            hasPrefetchedAfterInitialLoad = false
            imagePrefetchers.forEach { $0.stop() }
            imagePrefetchers.removeAll()
            delayedBackgroundFetch?.cancel()
            delayedBackgroundFetch = nil
        }

        let fetchCount = (reset && !hasPrefetchedAfterInitialLoad) ? initialPageSize : pageSize
        isFetching = true
        if reset && !isBackgroundPrefetch {
            setupLottie()
        }
        ShelterManager.shared.fetchData(skip: skip, top: fetchCount, filter: currentFilter) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedAnimals):
                    let filteredAnimals = fetchedAnimals.filter { !$0.albumFile.isEmpty }
                    self.hasMoreData = fetchedAnimals.count >= fetchCount
                    self.skip += fetchedAnimals.count
                    if reset {
                        self.animalDatas = filteredAnimals
                        self.collectionView.reloadData()
                        // 可見 cell 已經以 high priority 開始下載，
                        // 接著 prefetch 螢幕外的圖片（跳過前幾張避免 priority 衝突）
                        let visibleCount = min(self.estimatedVisibleCellCount, filteredAnimals.count)
                        let remaining = Array(filteredAnimals.dropFirst(visibleCount))
                        if !remaining.isEmpty {
                            self.prefetchImages(from: remaining, limit: remaining.count)
                        }
                    } else {
                        let startIndex = self.animalDatas.count
                        let indexPaths = (startIndex..<(startIndex + filteredAnimals.count)).map {
                            IndexPath(item: $0, section: 0)
                        }
                        self.collectionView.performBatchUpdates({
                            self.animalDatas.append(contentsOf: filteredAnimals)
                            self.collectionView.insertItems(at: indexPaths)
                        })
                    }
                    if reset {
                        self.hasPrefetchedAfterInitialLoad = true
                    }
                case .failure(let error):
                    print(error)
                }
                self.isFetching = false
                self.pageStatus = .notLoadingMore
                self.loadingAnimationView.isHidden = true
                completion?()
                if reset && !isBackgroundPrefetch && self.hasMoreData {
                    if self.currentFilter == nil {
                        self.fetchData(isBackgroundPrefetch: true)
                    } else {
                        // 篩選時延遲 1.5 秒再抓下一頁，讓可見 cell 的 high priority 下載先跑
                        let filterSnapshot = self.currentFilter
                        let workItem = DispatchWorkItem { [weak self] in
                            guard let self = self,
                                  !self.isFetching,
                                  self.hasMoreData,
                                  self.currentFilter == filterSnapshot
                            else { return }
                            self.fetchData(isBackgroundPrefetch: true)
                        }
                        self.delayedBackgroundFetch = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
                    }
                }
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
        loadingAnimationView.isHidden = false
        loadingAnimationView.play(fromFrame: 0, toFrame: 288, loopMode: .playOnce, completion: { [weak self] _ in
            self?.loadingAnimationView.isHidden = true
        })
    }
    
    private func prefetchImages(from animals: [AnimalData], limit: Int) {
        let urls = animals.prefix(limit).compactMap { URL(string: $0.albumFile) }
        guard !urls.isEmpty else { return }
        let prefetcher = ImagePrefetcher(
            urls: urls,
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(URLSessionTask.lowPriority)
            ]
        )
        imagePrefetchers.append(prefetcher)
        prefetcher.start()
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
        animalDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? HomeCollectionViewCell
        else { return UICollectionViewCell() }
        let item = self.animalDatas[indexPath.item]
        cell.shelterImageView.kf.setImage(
            with: URL(string: item.albumFile),
            placeholder: UIImage(named: "dketch-4"),
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(1.0),
                // 連線停滯時 10 秒逾時後重試，避免佔位圖永久停留（見 docs/superpowers/specs/2026-07-10-image-loading-perf-design.md）
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1)))
            ]
        )
        cell.sexLabel.text = ShelterManager.shared.sexCh(sex: item.sex)
        cell.placeLabel.text = ShelterManager.shared.areaName(pkid: item.areaPkid)
        let sexImageName: String
        switch item.sex {
        case "M": sexImageName = "BOY-1"
        case "F": sexImageName = "GIRL-1"
        default:  sexImageName = "paws"
        }
        cell.sexImageView.image = UIImage(named: sexImageName)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeDetailViewController") as? HomeDetailViewController else { return }
        let pet = animalDatas[indexPath.item]
        detailVC.pet = pet
        if let cell = collectionView.cellForItem(at: indexPath) as? HomeCollectionViewCell {
            detailVC.placeholderImage = cell.shelterImageView.image
        }
        if let url = URL(string: pet.albumFile) {
            KingfisherManager.shared.retrieveImage(with: url, options: [.cacheOriginalImage]) { _ in }
        }
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView.contentSize.height > self.collectionView.frame.height,
              self.pageStatus == .notLoadingMore,
              hasMoreData else { return }
        if scrollView.contentSize.height - (scrollView.frame.size.height + scrollView.contentOffset.y) <= -10 {
            self.pageStatus = .loadingMore
            self.fetchData()
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
        let isEmpty = (filter.kind ?? "").isEmpty
            && (filter.sex ?? "").isEmpty
            && (filter.bodytype ?? "").isEmpty
            && filter.areaPkid == nil
        currentFilter = isEmpty ? nil : filter
        fetchData(reset: true)
    }
}

extension HomeViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard animalDatas.indices.contains(indexPath.item) else { return nil }
            return URL(string: animalDatas[indexPath.item].albumFile)
        }
        guard !urls.isEmpty else { return }
        let prefetcher = ImagePrefetcher(
            urls: urls,
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(URLSessionTask.lowPriority)
            ]
        )
        imagePrefetchers.append(prefetcher)
        prefetcher.start()
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // Keep prefetch alive to reduce visible image blanking while fast scrolling.
    }
}
