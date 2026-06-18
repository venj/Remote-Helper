# Remote Helper (远程下载助手) - Agent Guidelines & Context

This document outlines the codebase structure, architectural design, and styling guidelines of the **Remote Helper** project to assist agent development.

---

## 1. Project Overview
**Remote Helper** is an iOS/macOS (via Project Catalyst) application designed as a client to manage torrents, search magnet links, and trigger remote downloads.
* **Integrations**: It interacts with a custom [movie_server](https://github.com/venj/movie_server) backend, a Transmission server, or Xiaomi routers (Mi Remote). It also supports running in standalone mode (without the movie_server backend).
* **Language/Platform**: Swift, built with UIKit, targeting iOS and macOS (Catalyst). It uses the Swift Package Manager (SPM) for dependencies.

---

## 2. Codebase Structure

Key files and directories in `Remote Helper/`:

* **App Lifecycle**:
  * [AppDelegate.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/AppDelegate.swift): Initializes network settings (Alamofire) and registers iCloud sync observation (`NSUbiquitousKeyValueStore`).
  * [SceneDelegate.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/SceneDelegate.swift): Manages windows, handles catalyst title bar settings, and process lifecycles.

* **Configuration & Storage**:
  * [Configuration.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/Configuration.swift): Application settings manager storing details for Host, Transmission, Mi Remote, and customization settings.
  * [Constants.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/Constants.swift): Central repository for constants, notification names, and user default keys.
  * [PersistenceController.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/PersistenceController.swift): Handles Core Data persistence.

* **Business Logic & Helpers**:
  * [Helper.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/Helper.swift): General utility methods.
  * [Helper+iOS.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/Helper+iOS.swift): Core downloading triggers, alert handlers, and communication interfaces for Transmission and Mi Remote.
  * [MiDownloader.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/MiDownloader.swift): Deals with the authentication and remote download actions on Xiaomi Router API.

* **Key View Controllers**:
  * [WebContentTableViewController.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/WebContentTableViewController.swift): Table-based rendering of links, files, and resources. Includes entry for opening `PasteboardListViewController`.
  * [VPTorrentsListViewController.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/VPTorrentsListViewController.swift): Renders downloaded torrent lists.
  * [VPSearchResultController.swift](file:///Users/venj/Developer/Github/Remote%20Helper/Remote%20Helper/VPSearchResultController.swift): Handles torrent search and results visualization.

---

## 3. Key Frameworks & Dependencies
* **Alamofire**: Used for network calls. Configuration details (e.g. custom user agent, SSL configurations) are handled in `AppDelegate.swift` and `Configuration.swift`.
* **Kingfisher**: Handles remote image loading and cache clearing on application backgrounding.
* **PasscodeLock**: Used for secure lock screen presentation (`UserDefaultsPasscodeRepository.swift`, `PasscodeLockConfiguration.swift`).

---

## 4. Key Mechanisms to Know

### A. Clipboard Magnet Detection (User-Triggered)
* **Trigger**: Triggered interactively via "Download from Pasteboard" action in `WebContentTableViewController`.
* **Pasteboard Access (iOS 16+)**: Uses `UIPasteControl` inside a custom navigation-wrapped `PasteboardListViewController` to securely retrieve text content without triggering the iOS system paste banner.
* **Presentation**: When the pasteboard is read, magnet links are parsed. If multiple links exist, they are displayed inside a non-interactive `UITableView`. Users can select "Download" in the navbar, which routes downloads through Transmission/Mi router.
* **De-duplication**: Tracks processed magnet links using SHA256 hashing to record last copied magnets.
* **Name Cleanup**: Cleaned up via `String.humanReadableFileName()`. If `dn=` or `btname=` query parameters are missing in the magnet link, the display name falls back to just the info hash query part (stripping trailing parameters like trackers `&tr=...`).

### B. Core Data & CloudKit Sync
* Reads/viewed history is synchronized through `NSUbiquitousKeyValueStore` key value change observers. Notification `viewedTitlesDidChangeNotification` is posted on changes to refresh standard UI tables.

---

## 5. Development Guidelines
* **Code Style**: Maintain clean Swift style. Follow standard Swift naming conventions and preserve existing architecture guidelines.
* **Localization**: Keep translations aligned in localization files (`zh-Hans.lproj` and `en.lproj`).
* **Catalyst Support**: Always verify conditional builds `#if targetEnvironment(macCatalyst)` when working with UI updates or system integrations.
