//
//  SidebarViewController.swift
//  Remote Helper
//
//  Created by Antigravity.
//

#if targetEnvironment(macCatalyst)
import UIKit

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ sidebar: SidebarViewController, didSelectIndex index: Int)
}

class SidebarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: SidebarViewControllerDelegate?
    private var tableView: UITableView!
    
    let items = [
        (title: NSLocalizedString("Addresses", comment: "Addresses"), image: "link"),
        (title: NSLocalizedString("Torrents", comment: "Torrents"), image: "arrow.down.circle"),
        (title: NSLocalizedString("DYTT", comment: "DYTT"), image: "film")
    ]
    
    var selectedIndex: Int = 0 {
        didSet {
            if isViewLoaded {
                tableView.selectRow(at: IndexPath(row: selectedIndex, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("Remote Helper", comment: "App Name")
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SidebarCell")
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        view.addSubview(tableView)
        
        // Select the default item
        tableView.selectRow(at: IndexPath(row: selectedIndex, section: 0), animated: false, scrollPosition: .none)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SidebarCell", for: indexPath)
        let item = items[indexPath.row]
        
        let selectedBGView = UIView()
        selectedBGView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.18)
        selectedBGView.layer.cornerRadius = 8
        cell.selectedBackgroundView = selectedBGView
        
        cell.configurationUpdateHandler = { cell, state in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = UIImage(systemName: item.image)
            
            if state.isSelected {
                content.textProperties.color = Helper.shared.mainThemeColor()
                content.imageProperties.tintColor = Helper.shared.mainThemeColor()
            } else {
                content.textProperties.color = .label
                content.imageProperties.tintColor = .secondaryLabel
            }
            cell.contentConfiguration = content
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        delegate?.sidebarViewController(self, didSelectIndex: indexPath.row)
    }
}
#endif
