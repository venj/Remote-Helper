import UIKit
import JXPhotoBrowser

final class PageNumberActionOverlay: UIView, JXPhotoBrowserOverlay, UIGestureRecognizerDelegate {
    struct ActionButtonStyle {
        var titleColor: UIColor
        var backgroundColor: UIColor
        var font: UIFont
        var contentInsets: UIEdgeInsets
        var cornerRadius: CGFloat

        static var `default`: ActionButtonStyle {
            ActionButtonStyle(
                titleColor: .white,
                backgroundColor: UIColor.black.withAlphaComponent(0.45),
                font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                contentInsets: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12),
                cornerRadius: 8
            )
        }
    }

    struct ActionButton {
        var title: String
        var style: ActionButtonStyle
        var onTap: ((PageNumberActionOverlay) -> Void)?

        init(title: String, style: ActionButtonStyle = .default, onTap: ((PageNumberActionOverlay) -> Void)? = nil) {
            self.title = title
            self.style = style
            self.onTap = onTap
        }
    }

    var pageTitleProvider: ((Int) -> String?)?
    var actionButtons: [ActionButton] = [
        ActionButton(title: "按钮1"),
        ActionButton(title: "按钮2")
    ] {
        didSet {
            if actionButtons.count > 2 {
                actionButtons = Array(actionButtons.prefix(2))
                return
            }
            renderActionButtons()
        }
    }

    private weak var browser: JXPhotoBrowserViewController?
    private var isOverlayContentHidden = false
    private lazy var overlayTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap))
        gesture.numberOfTapsRequired = 1
        gesture.cancelsTouchesInView = true
        gesture.delegate = self
        return gesture
    }()

    private(set) var currentPage: Int = 0
    private(set) var totalPages: Int = 0
    private var currentIndex: Int = 0

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private var actionUIButtons: [UIButton] = []
    private weak var installedContainer: UIView?
    private var containerConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setup(with browser: JXPhotoBrowserViewController) {
        self.browser = browser
        if overlayTapGesture.view !== browser.view {
            overlayTapGesture.view?.removeGestureRecognizer(overlayTapGesture)
            browser.view.addGestureRecognizer(overlayTapGesture)
        }
        disableVisibleCellSingleTap()
        bindVisibleCellDoubleTap()
        DispatchQueue.main.async { [weak self] in
            self?.disableVisibleCellSingleTap()
            self?.bindVisibleCellDoubleTap()
        }
        setOverlayContentHidden(false, animated: false)
        
        guard let container = superview else { return }
        guard installedContainer !== container || containerConstraints.isEmpty else { return }
        
        NSLayoutConstraint.deactivate(containerConstraints)
        containerConstraints = [
            topAnchor.constraint(equalTo: container.topAnchor),
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ]
        NSLayoutConstraint.activate(containerConstraints)
        installedContainer = container
    }

    func reloadData(numberOfItems: Int, pageIndex: Int) {
        totalPages = max(numberOfItems, 0)
        currentIndex = totalPages > 0 ? min(max(pageIndex, 0), totalPages - 1) : 0
        currentPage = totalPages > 0 ? (currentIndex + 1) : 0
        disableVisibleCellSingleTap()
        bindVisibleCellDoubleTap()
        updateLabel()
        updateTitle()
    }

    func didChangedPageIndex(_ index: Int) {
        currentIndex = totalPages > 0 ? min(max(index, 0), totalPages - 1) : 0
        currentPage = totalPages > 0 ? (currentIndex + 1) : 0
        disableVisibleCellSingleTap()
        bindVisibleCellDoubleTap()
        DispatchQueue.main.async { [weak self] in
            self?.disableVisibleCellSingleTap()
            self?.bindVisibleCellDoubleTap()
        }
        updateLabel()
        updateTitle()
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isUserInteractionEnabled = true

        addSubview(titleLabel)
        addSubview(pageLabel)
        addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -12),
            buttonStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: buttonStack.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 56),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -56),

            pageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
            pageLabel.heightAnchor.constraint(equalToConstant: 24),
            pageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])

        renderActionButtons()
        updateLabel()
        updateTitle()
    }

    private func renderActionButtons() {
        actionUIButtons.forEach { button in
            button.removeTarget(self, action: #selector(handleActionButtonTap(_:)), for: .touchUpInside)
            button.removeFromSuperview()
        }
        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionUIButtons.removeAll()

        for (index, model) in actionButtons.enumerated() {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = index
            button.setTitle(model.title, for: .normal)
            button.setTitleColor(model.style.titleColor, for: .normal)
            button.titleLabel?.font = model.style.font
            button.backgroundColor = model.style.backgroundColor
            button.layer.cornerRadius = model.style.cornerRadius
            button.contentEdgeInsets = model.style.contentInsets
            button.addTarget(self, action: #selector(handleActionButtonTap(_:)), for: .touchUpInside)
            buttonStack.addArrangedSubview(button)
            actionUIButtons.append(button)
        }

        // 与当前 overlay 隐藏状态保持一致
        let alpha: CGFloat = isOverlayContentHidden ? 0 : 1
        actionUIButtons.forEach {
            $0.alpha = alpha
            $0.isUserInteractionEnabled = !isOverlayContentHidden
        }
    }

    private func updateLabel() {
        pageLabel.text = "\(currentPage)/\(totalPages)"
    }

    private func updateTitle() {
        titleLabel.text = pageTitleProvider?(currentIndex)
    }

    @objc
    private func handleActionButtonTap(_ sender: UIButton) {
        guard actionButtons.indices.contains(sender.tag) else { return }
        actionButtons[sender.tag].onTap?(self)
    }

    @objc
    private func handleOverlayTap() {
        setOverlayContentHidden(!isOverlayContentHidden, animated: true)
    }

    private func setOverlayContentHidden(_ hidden: Bool, animated: Bool) {
        isOverlayContentHidden = hidden

        let updates = {
            self.titleLabel.alpha = hidden ? 0 : 1
            self.pageLabel.alpha = hidden ? 0 : 1
            self.actionUIButtons.forEach { $0.alpha = hidden ? 0 : 1 }
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }

        titleLabel.isUserInteractionEnabled = !hidden
        pageLabel.isUserInteractionEnabled = !hidden
        actionUIButtons.forEach { $0.isUserInteractionEnabled = !hidden }
    }

    private func disableVisibleCellSingleTap() {
        guard let browser = browser else { return }
        for cell in browser.collectionView.visibleCells {
            guard let zoomCell = cell as? JXZoomImageCell else { continue }
            zoomCell.singleTapGesture.isEnabled = false
        }
    }

    private func bindVisibleCellDoubleTap() {
        guard let browser = browser else { return }
        for cell in browser.collectionView.visibleCells {
            guard let zoomCell = cell as? JXZoomImageCell else { continue }
            overlayTapGesture.require(toFail: zoomCell.doubleTapGesture)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === overlayTapGesture else { return true }

        let location = touch.location(in: self)
        for button in actionUIButtons where button.isUserInteractionEnabled && button.alpha > 0.01 {
            let frame = convert(button.bounds, from: button)
            if frame.contains(location) {
                return false
            }
        }
        return true
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for button in actionUIButtons where button.isUserInteractionEnabled && button.alpha > 0.01 {
            let localPoint = convert(point, to: button)
            if button.point(inside: localPoint, with: event) {
                return true
            }
        }
        return false
    }
}
