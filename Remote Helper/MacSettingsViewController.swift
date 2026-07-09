//
//  MacSettingsViewController.swift
//  Remote Helper
//
//  Created by Antigravity.
//

#if targetEnvironment(macCatalyst)
import UIKit
import Kingfisher
import PasscodeLock

class MacSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var tableView: UITableView!
    private var rightContainer: UIScrollView!
    private var rightStack: UIStackView!
    
    private let categories = [
        NSLocalizedString("Server Settings", comment: ""),
        NSLocalizedString("Transmission Settings", comment: ""),
        NSLocalizedString("Magnet Search Settings", comment: ""),
        NSLocalizedString("Mi Remote Settings", comment: ""),
        NSLocalizedString("Network & Playback", comment: ""),
        NSLocalizedString("Cache & Storage", comment: ""),
        NSLocalizedString("Security & Info", comment: "")
    ]
    
    private let categoryIcons = [
        "desktopcomputer",
        "tray.and.arrow.down",
        "magnifyingglass",
        "wifi",
        "network",
        "square.stack.3d.up",
        "lock"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "")
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 640, height: 480)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        setupLayout()
        
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        showCategory(0)
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true) {
            UserDefaults.standard.set(true, forKey: ServerSetupDone)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func setupLayout() {
        // Left Table View
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tableView.backgroundColor = .secondarySystemBackground
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        // Vertical Separator
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator
        view.addSubview(separator)
        
        // Right Scroll View Container
        rightContainer = UIScrollView()
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightContainer)
        
        rightStack = UIStackView()
        rightStack.axis = .vertical
        rightStack.spacing = 16
        rightStack.alignment = .fill
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addSubview(rightStack)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.widthAnchor.constraint(equalToConstant: 180),
            
            separator.leadingAnchor.constraint(equalTo: tableView.trailingAnchor),
            separator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            separator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separator.widthAnchor.constraint(equalToConstant: 1),
            
            rightContainer.leadingAnchor.constraint(equalTo: separator.trailingAnchor),
            rightContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rightContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            rightStack.leadingAnchor.constraint(equalTo: rightContainer.contentLayoutGuide.leadingAnchor, constant: 24),
            rightStack.trailingAnchor.constraint(equalTo: rightContainer.contentLayoutGuide.trailingAnchor, constant: -24),
            rightStack.topAnchor.constraint(equalTo: rightContainer.contentLayoutGuide.topAnchor, constant: 24),
            rightStack.bottomAnchor.constraint(equalTo: rightContainer.contentLayoutGuide.bottomAnchor, constant: -24),
            rightStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -180 - 1 - 48)
        ])
    }
    
    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell") ?? UITableViewCell(style: .default, reuseIdentifier: "CategoryCell")
        cell.textLabel?.text = categories[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        cell.backgroundColor = .clear
        cell.selectionStyle = .gray
        
        let iconName = categoryIcons[indexPath.row]
        cell.imageView?.image = UIImage(systemName: iconName)
        cell.imageView?.tintColor = Helper.shared.mainThemeColor()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showCategory(indexPath.row)
    }
    
    // MARK: - Categories Switcher
    private func showCategory(_ index: Int) {
        // Clear previous subviews
        rightStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch index {
        case 0: // Server Settings
            addSectionHeader(title: NSLocalizedString("Server Settings", comment: ""))
            addTextFieldRow(label: NSLocalizedString("Host", comment: ""), key: ServerHostKey, placeholder: "-", defaultValue: "-")
            addTextFieldRow(label: NSLocalizedString("Port", comment: ""), key: ServerPortKey, placeholder: "80", defaultValue: "80")
            addTextFieldRow(label: NSLocalizedString("Path", comment: ""), key: ServerPathKey, placeholder: "/", defaultValue: "/")
            
        case 1: // Transmission Settings
            addSectionHeader(title: NSLocalizedString("Transmission Settings", comment: ""))
            addTextFieldRow(label: NSLocalizedString("Host", comment: ""), key: TransmissionAddressKey, placeholder: "127.0.0.1:9091", defaultValue: "127.0.0.1:9091")
            addTextFieldRow(label: NSLocalizedString("Username", comment: ""), key: TransmissionUserNameKey, placeholder: "username", defaultValue: "username")
            addTextFieldRow(label: NSLocalizedString("Password", comment: ""), key: TransmissionPasswordKey, placeholder: "password", defaultValue: "password", isSecure: true)
            addSwitchRow(label: NSLocalizedString("Intelligent Torrent Download", comment: ""), key: IntelligentTorrentDownload, defaultValue: false)
            addSwitchRow(label: NSLocalizedString("Prefers Magnet", comment: ""), key: PrefersMagnet, defaultValue: true)
            
        case 2: // Magnet Search Settings
            addSectionHeader(title: NSLocalizedString("Magnet Search Settings", comment: ""))
            addSegmentedControlRow(label: NSLocalizedString("Magnet Source", comment: ""), key: TorrentKittenSource, items: ["NYN", "NYS"], values: ["0", "1"])
            
        case 3: // Mi Remote Settings
            addSectionHeader(title: NSLocalizedString("Mi Remote Settings", comment: ""))
            addTextFieldRow(label: NSLocalizedString("Username", comment: ""), key: MiAccountUsernameKey, placeholder: "username", defaultValue: "username")
            addTextFieldRow(label: NSLocalizedString("Password", comment: ""), key: MiAccountPasswordKey, placeholder: "password", defaultValue: "password", isSecure: true)
            
        case 4: // Network & Playback
            addSectionHeader(title: NSLocalizedString("Request Settings", comment: ""))
            addTextFieldRow(label: NSLocalizedString("Custom UA", comment: ""), key: CustomRequestUserAgent, placeholder: "video-player", defaultValue: "video-player")
            addSwitchRow(label: NSLocalizedString("Use SSL", comment: ""), key: RequestUseSSL, defaultValue: true)
            addSwitchRow(label: NSLocalizedString("Use Cellular Network", comment: ""), key: RequestUseCellularNetwork, defaultValue: true)
            
            addSectionHeader(title: NSLocalizedString("GIF Playback", comment: ""))
            addSwitchRow(label: NSLocalizedString("Auto-Play GIF in Grid", comment: ""), key: AutoPlayGIFInGridKey, defaultValue: false)
            addSwitchRow(label: NSLocalizedString("Auto-Play GIF in Preview", comment: ""), key: AutoPlayGIFInPreviewKey, defaultValue: true)
            
        case 5: // Cache & Storage
            addSectionHeader(title: NSLocalizedString("Cache", comment: ""))
            let cacheLabel = addReadOnlyRow(label: NSLocalizedString("Cache Size", comment: ""), key: ImageCacheSizeKey)
            addSwitchRow(label: NSLocalizedString("Clear Cache On Exit", comment: ""), key: ClearCacheOnExitKey, defaultValue: false)
            
            addButtonRow(label: "", title: NSLocalizedString("Clear Cache Now", comment: "")) { [weak self] in
                Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: ""))
                ImageCache.default.clearDiskCache() {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let localFileSize = Helper.shared.fileSizeString(withInteger: Helper.shared.localFileSize())
                        ImageCache.default.calculateDiskStorageSize { result in
                            let cacheSizeInBytes = Int((try? result.get()) ?? 0)
                            let cacheSize = Helper.shared.fileSizeString(withInteger: cacheSizeInBytes)
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(cacheSize, forKey: ImageCacheSizeKey)
                                UserDefaults.standard.set(localFileSize, forKey: LocalFileSize)
                                UserDefaults.standard.synchronize()
                                cacheLabel.text = cacheSize
                                Helper.shared.showNote(withMessage: NSLocalizedString("Cache Cleared!", comment: ""))
                            }
                        }
                    }
                }
            }
            
            addSectionHeader(title: NSLocalizedString("Disk Storage", comment: ""))
            _ = addReadOnlyRow(label: NSLocalizedString("Local File Size", comment: ""), key: LocalFileSize)
            _ = addReadOnlyRow(label: NSLocalizedString("Device Free Space", comment: ""), key: DeviceFreeSpace)
            
        case 6: // Security & Info
            addSectionHeader(title: NSLocalizedString("Security", comment: ""))
            let passcodeLabel = addReadOnlyRow(label: NSLocalizedString("Passcode Lock", comment: ""), key: PasscodeLockStatus)
            
            addButtonRow(label: "", title: NSLocalizedString("Configure Passcode", comment: "")) { [weak self] in
                guard let self = self else { return }
                let repository = UserDefaultsPasscodeRepository()
                let configuration = PasscodeLockConfiguration(repository: repository)
                
                if !repository.hasPasscode {
                    let passcodeVC = PasscodeLockViewController(state: .setPasscode, configuration: configuration)
                    passcodeVC.successCallback = { lock in
                        let status = NSLocalizedString("On", comment: "")
                        Configuration.shared.save(status, forKey: PasscodeLockStatus)
                        UserDefaults.standard.set(status, forKey: PasscodeLockStatus)
                        UserDefaults.standard.synchronize()
                        passcodeLabel.text = status
                    }
                    passcodeVC.mainColor = Helper.shared.mainThemeColor()
                    self.navigationController?.pushViewController(passcodeVC, animated: true)
                } else {
                    let alert = UIAlertController(title: NSLocalizedString("Disable passcode", comment: ""), message: NSLocalizedString("You are going to disable passcode lock. Continue?", comment: ""), preferredStyle: .alert)
                    let confirmAction = UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
                        let passcodeVC = PasscodeLockViewController(state: .removePasscode, configuration: configuration)
                        passcodeVC.successCallback = { lock in
                            lock.repository.deletePasscode()
                            let status = NSLocalizedString("Off", comment: "")
                            Configuration.shared.save(status, forKey: PasscodeLockStatus)
                            UserDefaults.standard.set(status, forKey: PasscodeLockStatus)
                            UserDefaults.standard.synchronize()
                            passcodeLabel.text = status
                        }
                        passcodeVC.mainColor = Helper.shared.mainThemeColor()
                        self.navigationController?.pushViewController(passcodeVC, animated: true)
                    })
                    alert.addAction(confirmAction)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            addSectionHeader(title: NSLocalizedString("App Version", comment: ""))
            _ = addReadOnlyRow(label: NSLocalizedString("Version", comment: ""), key: CurrentVersionKey)
            
        default:
            break
        }
    }
    
    // MARK: - Form Building Helpers
    private func addSectionHeader(title: String) {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.textColor = Helper.shared.mainThemeColor()
        rightStack.addArrangedSubview(label)
    }
    
    private func addTextFieldRow(label: String, key: String, placeholder: String?, defaultValue: String, isSecure: Bool = false) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 13)
        labelView.textColor = .label
        row.addArrangedSubview(labelView)
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = placeholder
        tf.text = UserDefaults.standard.string(forKey: key) ?? defaultValue
        tf.isSecureTextEntry = isSecure
        tf.font = UIFont.systemFont(ofSize: 13)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.widthAnchor.constraint(equalToConstant: 240).isActive = true
        
        tf.addAction(UIAction(handler: { _ in
            UserDefaults.standard.set(tf.text ?? "", forKey: key)
            UserDefaults.standard.synchronize()
        }), for: .editingChanged)
        
        row.addArrangedSubview(tf)
        rightStack.addArrangedSubview(row)
    }
    
    private func addSwitchRow(label: String, key: String, defaultValue: Bool) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 13)
        labelView.textColor = .label
        row.addArrangedSubview(labelView)
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        
        let sw = UISwitch()
        sw.isOn = UserDefaults.standard.object(forKey: key) != nil ? UserDefaults.standard.bool(forKey: key) : defaultValue
        sw.onTintColor = Helper.shared.mainThemeColor()
        sw.addAction(UIAction(handler: { _ in
            UserDefaults.standard.set(sw.isOn, forKey: key)
            UserDefaults.standard.synchronize()
        }), for: .valueChanged)
        
        row.addArrangedSubview(sw)
        rightStack.addArrangedSubview(row)
    }
    
    private func addSegmentedControlRow(label: String, key: String, items: [String], values: [String]) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 13)
        labelView.textColor = .label
        row.addArrangedSubview(labelView)
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        
        let seg = UISegmentedControl(items: items)
        let currentVal = UserDefaults.standard.string(forKey: key) ?? values[0]
        if let idx = values.firstIndex(of: currentVal) {
            seg.selectedSegmentIndex = idx
        }
        
        seg.addAction(UIAction(handler: { _ in
            let selectedVal = values[seg.selectedSegmentIndex]
            UserDefaults.standard.set(selectedVal, forKey: key)
            UserDefaults.standard.synchronize()
        }), for: .valueChanged)
        
        row.addArrangedSubview(seg)
        rightStack.addArrangedSubview(row)
    }
    
    private func addReadOnlyRow(label: String, key: String) -> UILabel {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 13)
        labelView.textColor = .label
        row.addArrangedSubview(labelView)
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        
        let valView = UILabel()
        valView.text = UserDefaults.standard.string(forKey: key) ?? ""
        valView.font = UIFont.systemFont(ofSize: 13)
        valView.textColor = .secondaryLabel
        row.addArrangedSubview(valView)
        
        rightStack.addArrangedSubview(row)
        return valView
    }
    
    private func addButtonRow(label: String, title: String, action: @escaping () -> Void) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 13)
        labelView.textColor = .label
        row.addArrangedSubview(labelView)
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .highlighted)
        btn.backgroundColor = Helper.shared.mainThemeColor()
        btn.layer.cornerRadius = 6
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        btn.addAction(UIAction(handler: { _ in
            action()
        }), for: .touchUpInside)
        
        row.addArrangedSubview(btn)
        rightStack.addArrangedSubview(row)
    }
}
#endif
