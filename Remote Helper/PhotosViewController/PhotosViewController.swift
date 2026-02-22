//
//  PhotosViewController.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import Network
import Photos
import JXPhotoBrowser
import Kingfisher

// MARK: - ViewController
class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    private static let browserProgressViewTag = 99_001
    
    private var collectionView: UICollectionView!
    
    /// 可由外部替换的浏览器 Overlay 工厂（每次展示创建新实例，避免复用状态残留）
    var makeBrowserOverlay: () -> JXPhotoBrowserOverlay = { PageNumberActionOverlay() }
    
    /// 可由外部配置的大图 Overlay 按钮（支持 0~2 个）。
    /// 传 nil 或 [] 都表示不显示按钮。
    var overlayActionButtons: [PageNumberActionOverlay.ActionButton]? = nil
    
    /// 网络状态监视器（监听网络连通性变化）
    private let networkMonitor = NWPathMonitor()
    
    /// 网络监视器队列（后台监控网络状态）
    private let networkQueue = DispatchQueue(label: "com.demo.network.monitor")
    
    // 数据源（支持外部注入）
    var items: [RemoteMedia] = [] {
        didSet {
            if isViewLoaded, collectionView != nil {
                collectionView.reloadData()
            }
        }
    }
    
    private weak var photoBrowser: JXPhotoBrowserViewController?
    private var hasAutoPresentedBrowser = false
    private var failedThumbnailIndexes: Set<Int> = []
    
    /// 是否允许自动旋转
    open override var shouldAutorotate: Bool {
        return true
    }
    
    /// 支持的屏幕方向
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLocalImageCache()
//        setupDefaultDataIfNeeded()
        setupNetworkMonitoring()
        setupCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAutoPresentedBrowser else { return }
        guard !items.isEmpty else { return }
        hasAutoPresentedBrowser = true
        presentPhotoBrowser(at: 0)
    }
    
    private func setupDefaultDataIfNeeded() {
        guard items.isEmpty else { return }
        let base = URL(string: "https://raw.githubusercontent.com/JiongXing/MediaResources/master/PhotoBrowser")!
        
        // 图片数据
        let photos = (0..<9).map { i -> RemoteMedia in
            let original = base.appendingPathComponent("photo_\(i).png")
            let thumbnail = base.appendingPathComponent("photo_\(i)_thumbnail.png")
            return RemoteMedia(source: .remoteImage(imageURL: original, thumbnailURL: thumbnail))
        }
        
        // 视频数据
        let videos = (0..<3).map { i -> RemoteMedia in
            let videoURL = base.appendingPathComponent("video_\(i).mp4")
            let thumbnailURL = base.appendingPathComponent("video_thumbnail_\(i).png")
            return RemoteMedia(source: .remoteVideo(url: videoURL, thumbnailURL: thumbnailURL))
        }
        
        items = photos + videos
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let inset: CGFloat = 12
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MediaThumbnailCell.self, forCellWithReuseIdentifier: MediaThumbnailCell.reuseIdentifier)
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaThumbnailCell.reuseIdentifier, for: indexPath) as! MediaThumbnailCell
        cell.configure(with: items[indexPath.item])
        switch items[indexPath.item].source {
        case .remoteImage:
            cell.onImageLoadResult = { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.failedThumbnailIndexes.remove(indexPath.item)
                } else {
                    self.failedThumbnailIndexes.insert(indexPath.item)
                }
            }
        case .remoteVideo:
            cell.onImageLoadResult = nil
        }
        if let browser = photoBrowser, browser.pageIndex == indexPath.item {
            cell.imageView.isHidden = true
        } else {
            cell.imageView.isHidden = false
        }
        return cell
    }
    
    // MARK: - DelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 100, height: 100)
        }
        let minItemWidth: CGFloat = 110
        let baseColumns = 3
        let contentWidth = collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right
        let dynamicColumns = Int((contentWidth + flowLayout.minimumInteritemSpacing) / (minItemWidth + flowLayout.minimumInteritemSpacing))
        let columns = CGFloat(max(baseColumns, dynamicColumns))
        let totalSpacing = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / columns)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presentPhotoBrowser(at: indexPath.item)
    }
    
    private func presentPhotoBrowser(at index: Int) {
        guard items.indices.contains(index) else { return }
        let browser = JXPhotoBrowserViewController()
        browser.register(VideoPlayerCell.self, forReuseIdentifier: VideoPlayerCell.videoReuseIdentifier)
        browser.delegate = self
        browser.initialIndex = index
        
        // 默认配置
        browser.scrollDirection = .horizontal
        browser.transitionType = .zoom
        browser.itemSpacing = 20
        
        self.photoBrowser = browser
        
        let overlay = makeBrowserOverlay()
        
        if let overlay = overlay as? PageNumberActionOverlay {
            overlay.actionButtons = overlayActionButtons ?? []
            overlay.pageTitleProvider = { [weak self] index in
                guard let self = self, items.indices.contains(index) else { return nil }
                let media = items[index]
                switch media.source {
                case let .remoteImage(imageURL, _):
                    return imageURL.lastPathComponent
                case let .remoteVideo(url, _):
                    return url.lastPathComponent
                }
            }
        }
        
        browser.addOverlay(overlay)
        browser.present(from: self)
    }
    
    private func presentPlayer(with url: URL) {
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: url)
        present(playerVC, animated: true) {
            playerVC.player?.play()
        }
    }
}


// MARK: - JXPhotoBrowser Delegate
extension PhotosViewController: JXPhotoBrowserDelegate {
    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int {
        return items.count
    }
    
    func photoBrowser(_ browser: JXPhotoBrowserViewController, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let media = items[index]
        switch media.source {
        case .remoteImage:
            let cell = browser.dequeueReusableCell(withReuseIdentifier: JXZoomImageCell.reuseIdentifier, for: indexPath) as! JXZoomImageCell
            return cell
        case .remoteVideo:
            let cell = browser.dequeueReusableCell(withReuseIdentifier: VideoPlayerCell.videoReuseIdentifier, for: indexPath) as! VideoPlayerCell
            return cell
        }
    }
    
    func photoBrowser(_ browser: JXPhotoBrowserViewController, willDisplay cell: JXPhotoBrowserAnyCell, at index: Int) {
        let media = items[index]
        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            guard let photoCell = cell as? JXZoomImageCell else { return }
            print("[willDisplay] index: \(index), imageURL: \(imageURL)")
            let placeholder = thumbnailURL.flatMap { ImageCache.default.retrieveImageInMemoryCache(forKey: $0.absoluteString) }
            let progressView = browserProgressView(in: photoCell)
            let requestID = UUID().uuidString
            progressView.accessibilityIdentifier = requestID
            progressView.progress = 0
            progressView.isHidden = false
            photoCell.imageView.kf.cancelDownloadTask()

            var options = localCacheOptions
            if failedThumbnailIndexes.contains(index) {
                options.append(.forceRefresh)
            }
            options.append(contentsOf: refererOption(for: media.referer))

            photoCell.imageView.kf.setImage(
                with: imageURL,
                placeholder: placeholder,
                options: options,
                progressBlock: { receivedSize, totalSize in
                    guard progressView.accessibilityIdentifier == requestID else { return }
                    let progress: CGFloat
                    if totalSize > 0 {
                        progress = min(max(CGFloat(receivedSize) / CGFloat(totalSize), 0), 1)
                    } else {
                        progress = 0
                    }
                    DispatchQueue.main.async {
                        progressView.progress = progress
                        progressView.isHidden = false
                    }
                },
                completionHandler: { [weak self, weak photoCell] result in
                    guard progressView.accessibilityIdentifier == requestID else { return }
                    DispatchQueue.main.async {
                        progressView.progress = 1
                        progressView.isHidden = true
                        photoCell?.setNeedsLayout()
                    }
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            self.failedThumbnailIndexes.remove(index)
                            let indexPath = IndexPath(item: index, section: 0)
                            if let thumbCell = self.collectionView.cellForItem(at: indexPath) as? MediaThumbnailCell {
                                thumbCell.applyLoadedPreviewImage(photoCell?.imageView.image)
                            } else {
                                self.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    case let .failure(error):
                        if error.isTaskCancelled || error.isNotCurrentTask {
                            return
                        }
                        DispatchQueue.main.async {
                            self?.failedThumbnailIndexes.insert(index)
                        }
                    }
                }
            )
        case let .remoteVideo(videoURL, thumbnailURL):
            guard let videoCell = cell as? VideoPlayerCell else { return }
            print("[willDisplay] index: \(index), videoURL: \(videoURL)")
            // 先尝试从内存缓存同步获取封面图
            let memoryImage = ImageCache.default.retrieveImageInMemoryCache(forKey: thumbnailURL.absoluteString)
            videoCell.configure(videoURL: videoURL, coverImage: memoryImage)
            
            // 内存缓存为空时（如 App 从后台恢复后缓存被清理），异步从磁盘/网络加载封面图
            if memoryImage == nil {
                let options = localCacheOptions + refererOption(for: media.referer)
                videoCell.imageView.kf.setImage(with: thumbnailURL, options: options, completionHandler: { [weak videoCell] _ in
                    videoCell?.setNeedsLayout()
                })
            }
        }
    }
    
    func photoBrowser(_ browser: JXPhotoBrowserViewController, didEndDisplaying cell: JXPhotoBrowserAnyCell, at index: Int) {
        if let photoCell = cell as? JXZoomImageCell {
            photoCell.imageView.kf.cancelDownloadTask()
            if let progressView = photoCell.contentView.viewWithTag(Self.browserProgressViewTag) as? CircularProgressView {
                progressView.progress = 0
                progressView.isHidden = true
            }
        }

        // 停止视频播放
        if let videoCell = cell as? VideoPlayerCell {
            videoCell.stopVideo()
        }
    }
    
    // 为 Zoom 转场提供列表中的缩略图视图（用于起止位置计算）
    func photoBrowser(_ browser: JXPhotoBrowserViewController, thumbnailViewAt index: Int) -> UIView? {
        let ip = IndexPath(item: index, section: 0)
        guard let cell = collectionView.cellForItem(at: ip) as? MediaThumbnailCell else { return nil }
        return cell.imageView
    }
    
    // 控制缩略图的显隐（Zoom 转场时隐藏源视图，避免视觉重叠）
    func photoBrowser(_ browser: JXPhotoBrowserViewController, setThumbnailHidden hidden: Bool, at index: Int) {
        let ip = IndexPath(item: index, section: 0)
        if let cell = collectionView.cellForItem(at: ip) as? MediaThumbnailCell {
            cell.imageView.isHidden = hidden
        }
    }
}

private extension PhotosViewController {
    func browserProgressView(in cell: JXZoomImageCell) -> CircularProgressView {
        if let existing = cell.contentView.viewWithTag(Self.browserProgressViewTag) as? CircularProgressView {
            return existing
        }

        let progressView = CircularProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tag = Self.browserProgressViewTag
        progressView.isHidden = true
        progressView.progress = 0
        cell.contentView.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 32),
            progressView.heightAnchor.constraint(equalToConstant: 32)
        ])
        return progressView
    }
}

// MARK: - Network Monitoring
private extension PhotosViewController {
    func refererOption(for referer: String?) -> KingfisherOptionsInfo {
        guard let referer, !referer.isEmpty else { return [] }
        return [.requestModifier(AnyModifier { request in
            var req = request
            req.setValue(referer, forHTTPHeaderField: "Referer")
            return req
        })]
    }
    
    var localCacheOptions: KingfisherOptionsInfo {
        [
            .cacheOriginalImage,
            .memoryCacheExpiration(.days(1)),
            .loadDiskFileSynchronously
        ]
    }

    func configureLocalImageCache() {
        ImageCache.default.diskStorage.config.expiration = .never
        ImageCache.default.diskStorage.config.sizeLimit = 0
        #if KINGFISHER_V6
        ImageCache.default.diskStorage.config.autoExtAfterHashedFileName = true
        #endif
        ImageCache.default.memoryStorage.config.expiration = .days(1)
        ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
    }

    /// 启动网络权限/连通性监控，连通后刷新列表以触发加载
    func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let ready = (path.status == .satisfied)
            if ready {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    /// 下载图片 / 视频并保存到系统相册
    func downloadToAlbum(imageURL: URL?, videoURL: URL?, presentingViewController: UIViewController) {
        requestPhotoAuthorization { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                DispatchQueue.main.async {
                    self.presentToast(message: "未获得相册权限，无法保存", on: presentingViewController)
                }
                return
            }
            
            if let videoURL = videoURL {
                self.downloadVideoAndSave(videoURL, presentingViewController: presentingViewController)
            } else if let imageURL = imageURL {
                self.downloadImageAndSave(imageURL, presentingViewController: presentingViewController)
            }
        }
    }
    
    /// 请求相册权限
    func requestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { newStatus in
            completion(newStatus == .authorized)
        }
    }
    
    /// 下载图片后保存
    func downloadImageAndSave(_ url: URL, presentingViewController: UIViewController) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.presentToast(message: "图片下载失败", on: presentingViewController)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                DispatchQueue.main.async {
                    self.presentToast(message: success ? "已保存到系统相册" : "保存失败", on: presentingViewController)
                }
            }
        }.resume()
    }
    
    /// 下载视频后保存
    func downloadVideoAndSave(_ url: URL, presentingViewController: UIViewController) {
        URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.presentToast(message: "视频下载失败", on: presentingViewController)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            }) { success, _ in
                DispatchQueue.main.async {
                    self.presentToast(message: success ? "已保存到系统相册" : "保存失败", on: presentingViewController)
                }
            }
        }.resume()
    }
    
    /// 简单提示
    func presentToast(message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}
