//
//  MediaThumbnailCell.swift
//  Demo
//
//  Created by jxing on 2025/10/24.
//

import UIKit
import AVKit
import AVFoundation
import Kingfisher
import JXPhotoBrowser

final class MediaThumbnailCell: UICollectionViewCell {
    
    // MARK: - Static Properties
    
    /// 复用标识符
    static let reuseIdentifier = "MediaCell"
    private static let loadingBorderWidth: CGFloat = 1
    private static let loadingBorderColor: UIColor = .systemGray5
    var onImageLoadResult: ((Bool) -> Void)?
    private var loadToken = UUID()
    
    // MARK: - UI Components
    
    /// 主要的图片显示视图
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    /// 圆形加载进度视图
    private let progressView: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    /// 视频播放按钮覆盖层
    private let playOverlay: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    /// 加载失败图标
    private let failureOverlay: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup Methods
    
    private func setup() {
        contentView.addSubview(imageView)
        contentView.addSubview(playOverlay)
        contentView.addSubview(failureOverlay)
        contentView.addSubview(progressView)
        setLoadingBorderVisible(false)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playOverlay.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playOverlay.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playOverlay.widthAnchor.constraint(equalToConstant: 40),
            playOverlay.heightAnchor.constraint(equalToConstant: 40),
            failureOverlay.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            failureOverlay.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            failureOverlay.widthAnchor.constraint(equalToConstant: 30),
            failureOverlay.heightAnchor.constraint(equalToConstant: 30),
            progressView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 28),
            progressView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    // MARK: - Lifecycle Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.isHidden = false
        playOverlay.isHidden = true
        failureOverlay.isHidden = true
        progressView.progress = 0
        progressView.isHidden = true
        setLoadingBorderVisible(false)
        onImageLoadResult = nil
        loadToken = UUID()
    }
    
    // MARK: - Configuration Methods

    private var localCacheOptions: KingfisherOptionsInfo {
        [
            .cacheOriginalImage,
            .diskCacheExpiration(.days(30)),
            .memoryCacheExpiration(.days(1)),
            .loadDiskFileSynchronously
        ]
    }

    /// 配置 Cell 内容
    func configure(with media: RemoteMedia) {
        let token = UUID()
        loadToken = token
        imageView.image = nil
        playOverlay.isHidden = true
        failureOverlay.isHidden = true
        progressView.progress = 0
        progressView.isHidden = false
        setLoadingBorderVisible(true)

        let completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { [weak self] result in
            guard let self = self else { return }
            guard self.loadToken == token else { return }
            // 完成后立即失效当前 token，避免少数情况下进度回调晚到又把进度圈显示出来。
            self.loadToken = UUID()
            DispatchQueue.main.async {
                self.progressView.progress = 1
                self.progressView.isHidden = true
                switch result {
                case .success:
                    self.failureOverlay.isHidden = true
                    self.setLoadingBorderVisible(false)
                    self.onImageLoadResult?(true)
                case let .failure(error):
                    if error.isTaskCancelled || error.isNotCurrentTask {
                        return
                    }
                    self.failureOverlay.isHidden = false
                    self.playOverlay.isHidden = true
                    self.setLoadingBorderVisible(true)
                    self.onImageLoadResult?(false)
                }
            }
        }
        
        let progressHandler: DownloadProgressBlock = { [weak self] receivedSize, totalSize in
            guard let self = self else { return }
            guard self.loadToken == token else { return }
            let progress: CGFloat
            if totalSize > 0 {
                progress = min(max(CGFloat(receivedSize) / CGFloat(totalSize), 0), 1)
            } else {
                progress = 0
            }
            DispatchQueue.main.async {
                self.progressView.progress = progress
                self.progressView.isHidden = false
            }
        }

        switch media.source {
        case let .remoteImage(imageURL, thumbnailURL):
            let url = thumbnailURL ?? imageURL
            imageView.kf.setImage(
                with: url,
                options: localCacheOptions,
                progressBlock: progressHandler,
                completionHandler: completionHandler
            )

        case let .remoteVideo(_, thumbnailURL):
            playOverlay.isHidden = false
            imageView.kf.setImage(
                with: thumbnailURL,
                options: localCacheOptions,
                progressBlock: progressHandler,
                completionHandler: completionHandler
            )
        }
    }
    
    // MARK: - Private Methods

    func applyLoadedPreviewImage(_ image: UIImage?) {
        guard let image = image else { return }
        imageView.image = image
        failureOverlay.isHidden = true
        progressView.progress = 1
        progressView.isHidden = true
        setLoadingBorderVisible(false)
    }

    private func setLoadingBorderVisible(_ visible: Bool) {
        contentView.layer.borderWidth = visible ? Self.loadingBorderWidth : 0
        contentView.layer.borderColor = visible ? Self.loadingBorderColor.cgColor : UIColor.clear.cgColor
    }
}
