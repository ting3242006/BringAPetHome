//
//  ViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/6/14.
//

// [PERF] 量測碼使檔案暫時超過 400 行，Phase 2 清理時連同此註解移除
// swiftlint:disable file_length

import UIKit
import Kingfisher
import Lottie
import MJRefresh

// 頁面狀態
enum PageStatus {
    case loadingMore
    case notLoadingMore
}

#if DEBUG
private enum PerfLog {
    static let appStart = CFAbsoluteTimeGetCurrent()
    private static let lock = NSLock()
    private static var inFlightCount = 0

    @discardableResult
    static func adjustInFlight(by delta: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        inFlightCount += delta
        return inFlightCount
    }

    static func currentInFlight() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return inFlightCount
    }

    static func log(_ message: String) {
        let elapsed = String(format: "%.3f", CFAbsoluteTimeGetCurrent() - appStart)
        print("[PERF][t+\(elapsed)s] \(message)")
    }
}
#endif

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
    private let maxConcurrentCellDownloads = 4
    private var activeCellDownloads = 0
    private var pendingCellLoads: [(indexPath: IndexPath, urlString: String)] = []
    #if DEBUG
    private var hasLoggedFirstImageSinceReset = false
    #endif
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
        #if DEBUG
        PerfLog.log("anchor viewDidLoad")
        #endif
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
            pendingCellLoads.removeAll()
            #if DEBUG
            hasLoggedFirstImageSinceReset = false
            #endif
        }

        let fetchCount = (reset && !hasPrefetchedAfterInitialLoad) ? initialPageSize : pageSize
        isFetching = true
        if reset && !isBackgroundPrefetch {
            setupLottie()
        }
        #if DEBUG
        PerfLog.log("api request skip=\(skip) top=\(fetchCount) reset=\(reset) bg=\(isBackgroundPrefetch)")
        #endif
        ShelterManager.shared.fetchData(skip: skip, top: fetchCount, filter: currentFilter) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedAnimals):
                    #if DEBUG
                    PerfLog.log("anchor apiDone fetched=\(fetchedAnimals.count) reset=\(reset)")
                    #endif
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
    
    #if DEBUG
    private func perfPrefetchProgressBlock() -> PrefetcherProgressBlock {
        return { skipped, failed, completed in
            let inflight = PerfLog.adjustInFlight(by: -1)
            let done = skipped.count + failed.count + completed.count
            if done % 10 == 0 {
                PerfLog.log("prefetch progress done=\(done) inflight=\(inflight)")
            }
        }
    }
    #endif

    private func loadCellImage(_ cell: HomeCollectionViewCell, urlString: String, at indexPath: IndexPath) {
        let cached = ImageCache.default.imageCachedType(
            forKey: urlString, processorIdentifier: thumbnailProcessor.identifier).cached
        if cached || activeCellDownloads < maxConcurrentCellDownloads {
            startCellDownload(cell, urlString: urlString, at: indexPath)
        } else if !pendingCellLoads.contains(where: { $0.indexPath == indexPath }) {
            cell.shelterImageView.image = UIImage(named: "dketch-4")
            pendingCellLoads.append((indexPath, urlString))
            #if DEBUG
            PerfLog.log("cellQueue enqueue item=\(indexPath.item) pending=\(pendingCellLoads.count)")
            #endif
        }
    }

    private func startCellDownload(_ cell: HomeCollectionViewCell, urlString: String, at indexPath: IndexPath) {
        activeCellDownloads += 1
        #if DEBUG
        let requestStart = CFAbsoluteTimeGetCurrent()
        PerfLog.log("cellStart item=\(indexPath.item) active=\(activeCellDownloads)")
        #endif
        cell.shelterImageView.kf.setImage(
            with: URL(string: urlString),
            placeholder: UIImage(named: "dketch-4"),
            options: [
                .processor(thumbnailProcessor),
                .scaleFactor(UIScreen.main.scale),
                .backgroundDecode,
                .downloadPriority(1.0),
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 2, retryInterval: .seconds(1)))
            ],
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                self.activeCellDownloads -= 1
                self.drainPendingCellLoads()
                #if DEBUG
                let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - requestStart) * 1000)
                switch result {
                case .success(let value):
                    let cache = String(describing: value.cacheType)
                    PerfLog.log("cell item=\(indexPath.item) cache=\(cache) \(elapsedMs)ms active=\(self.activeCellDownloads)")
                    if !self.hasLoggedFirstImageSinceReset {
                        self.hasLoggedFirstImageSinceReset = true
                        PerfLog.log("anchor firstImage item=\(indexPath.item)")
                    }
                case .failure(let error):
                    guard !error.isTaskCancelled else { return }
                    PerfLog.log("cell item=\(indexPath.item) FAIL \(elapsedMs)ms code=\(error.errorCode)")
                }
                #endif
            }
        )
    }

    private func drainPendingCellLoads() {
        while activeCellDownloads < maxConcurrentCellDownloads, !pendingCellLoads.isEmpty {
            let next = pendingCellLoads.removeFirst()
            guard let cell = collectionView.cellForItem(at: next.indexPath) as? HomeCollectionViewCell else {
                #if DEBUG
                PerfLog.log("cellQueue skip offscreen item=\(next.indexPath.item)")
                #endif
                continue
            }
            startCellDownload(cell, urlString: next.urlString, at: next.indexPath)
        }
    }

    private func prefetchImages(from animals: [AnimalData], limit: Int) {
        let urls = animals.prefix(limit).compactMap { URL(string: $0.albumFile) }
        guard !urls.isEmpty else { return }
        let options: KingfisherOptionsInfo = [
            .processor(thumbnailProcessor),
            .scaleFactor(UIScreen.main.scale),
            .backgroundDecode,
            .downloadPriority(URLSessionTask.lowPriority)
        ]
        #if DEBUG
        PerfLog.log("prefetch start +\(urls.count) inflight=\(PerfLog.adjustInFlight(by: urls.count))")
        let prefetcher = ImagePrefetcher(urls: urls, options: options,
                                         progressBlock: perfPrefetchProgressBlock())
        #else
        let prefetcher = ImagePrefetcher(urls: urls, options: options)
        #endif
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
        loadCellImage(cell, urlString: item.albumFile, at: indexPath)
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
        let options: KingfisherOptionsInfo = [
            .processor(thumbnailProcessor),
            .scaleFactor(UIScreen.main.scale),
            .backgroundDecode,
            .downloadPriority(URLSessionTask.lowPriority)
        ]
        #if DEBUG
        PerfLog.log("prefetch start +\(urls.count) inflight=\(PerfLog.adjustInFlight(by: urls.count))")
        let prefetcher = ImagePrefetcher(urls: urls, options: options,
                                         progressBlock: perfPrefetchProgressBlock())
        #else
        let prefetcher = ImagePrefetcher(urls: urls, options: options)
        #endif
        imagePrefetchers.append(prefetcher)
        prefetcher.start()
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // Keep prefetch alive to reduce visible image blanking while fast scrolling.
    }
}
