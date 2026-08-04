//
//  XunleiDownloader.swift
//  Remote Helper
//
//  迅雷 NAS 目前没有稳定公开的第三方 API。这里对接的是群晖迅雷面板使用的
//  drive/v1 内部接口，并把“解析资源”和“创建任务”拆成两步，给用户留下文件筛选机会。
//

import Foundation
import Alamofire

struct XunleiTaskFile: Hashable {
    let index: Int
    let name: String
    let size: Int64
}

struct XunleiResource {
    let name: String
    let fileCount: Int
    let files: [XunleiTaskFile]
}

enum XunleiDownloaderError: LocalizedError {
    case configuration(String)
    case connection(String)
    case authentication(String)
    case response(String)
    case invalidResource(String)
    case noFilesSelected

    var errorDescription: String? {
        switch self {
        case .configuration(let message),
             .connection(let message),
             .authentication(let message),
             .response(let message),
             .invalidResource(let message):
            return message
        case .noFilesSelected:
            return NSLocalizedString("Select at least one file.", comment: "No Xunlei files selected")
        }
    }
}

final class XunleiDownloader {
    private let apiPrefix = "/webman/3rdparty/pan-xunlei-com/index.cgi"
    private let configuration: Configuration
    private let serverAddress: String

    private var panAuth: String?
    private var deviceID: String?
    private var downloadFolderID: String?
    private var downloadFolderName: String?

    init(configuration: Configuration = .shared) {
        self.configuration = configuration
        self.serverAddress = configuration.xunleiServerAddress()
    }

    var isConfigured: Bool {
        return configuration.hasXunleiServer
    }

    func testConnection(completion: @escaping (Swift.Result<String, XunleiDownloaderError>) -> Void) {
        ensureReady { result in
            switch result {
            case .success:
                completion(.success(self.downloadFolderName ?? ""))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchResource(for magnet: String, completion: @escaping (Swift.Result<XunleiResource, XunleiDownloaderError>) -> Void) {
        guard isConfigured else {
            completion(.failure(.configuration(NSLocalizedString("Please enter the Xunlei NAS address in Settings first.", comment: "Missing Xunlei address"))))
            return
        }

        let trimmedMagnet = magnet.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedMagnet.lowercased().hasPrefix("magnet:") else {
            completion(.failure(.invalidResource(NSLocalizedString("Xunlei NAS file selection currently requires a magnet link.", comment: "Unsupported Xunlei resource"))))
            return
        }

        ensureReady { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                let url = self.apiURL("drive/v1/resource/list?device_space=")
                let body: Parameters = ["urls": trimmedMagnet]
                self.makeRequest(url, method: .post, parameters: body, encoding: JSONEncoding(options: []))
                    .responseJSON { response in
                        guard response.result.isSuccess,
                              let object = response.result.value as? [String: Any] else {
                            completion(.failure(self.connectionError(from: response)))
                            return
                        }

                        do {
                            completion(.success(try self.resource(from: object)))
                        } catch let error as XunleiDownloaderError {
                            completion(.failure(error))
                        } catch {
                            completion(.failure(.invalidResource(error.localizedDescription)))
                        }
                    }
            }
        }
    }

    func addTask(for magnet: String,
                 resource: XunleiResource,
                 selectedFiles: [XunleiTaskFile],
                 completion: @escaping (Swift.Result<Void, XunleiDownloaderError>) -> Void) {
        guard !selectedFiles.isEmpty else {
            completion(.failure(.noFilesSelected))
            return
        }

        ensureReady { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                let body: Parameters = [
                    "type": "user#download-url",
                    "name": resource.name,
                    "file_name": resource.name,
                    "file_size": String(selectedFiles.reduce(Int64(0)) { $0 + $1.size }),
                    "space": self.deviceID ?? "",
                    "params": [
                        "target": self.deviceID ?? "",
                        "url": magnet,
                        "total_file_count": String(resource.fileCount),
                        "parent_folder_id": self.downloadFolderID ?? "",
                        "sub_file_index": selectedFiles.map { String($0.index) }.joined(separator: ","),
                        "file_id": ""
                    ]
                ]
                let url = self.apiURL("drive/v1/task?device_space=")
                self.makeRequest(url, method: .post, parameters: body, encoding: JSONEncoding(options: []))
                    .responseJSON { response in
                        guard response.result.isSuccess,
                              let object = response.result.value as? [String: Any] else {
                            completion(.failure(self.connectionError(from: response)))
                            return
                        }

                        if self.isSuccessful(object) {
                            completion(.success(()))
                        } else {
                            completion(.failure(.response(self.serverMessage(from: object))))
                        }
                    }
            }
        }
    }

    // MARK: - Session preparation

    private func ensureReady(completion: @escaping (Swift.Result<Void, XunleiDownloaderError>) -> Void) {
        guard isConfigured else {
            completion(.failure(.configuration(NSLocalizedString("Please enter the Xunlei NAS address in Settings first.", comment: "Missing Xunlei address"))))
            return
        }

        if panAuth != nil, deviceID != nil, downloadFolderID != nil {
            completion(.success(()))
            return
        }

        fetchPanAuth { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.fetchDeviceID { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        self.fetchDownloadFolder(completion: completion)
                    }
                }
            }
        }
    }

    private func fetchPanAuth(completion: @escaping (Swift.Result<String, XunleiDownloaderError>) -> Void) {
        let request = makeRequest(apiURL("/"), method: .get, requiresPanAuth: false)
        request.responseString { [weak self] response in
            guard let self = self else { return }
            guard response.result.isSuccess, let html = response.result.value else {
                completion(.failure(self.connectionError(from: response)))
                return
            }

            let pattern = "function\\s+uiauth\\(value\\)\\s*\\{\\s*return\\s+\"([^\"]+)\""
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let tokenRange = Range(match.range(at: 1), in: html) else {
                completion(.failure(.authentication(NSLocalizedString("Could not obtain an authentication token from the Xunlei NAS panel.", comment: "Xunlei authentication error"))))
                return
            }

            let token = String(html[tokenRange])
            self.panAuth = token
            completion(.success(token))
        }
    }

    private func fetchDeviceID(completion: @escaping (Swift.Result<String, XunleiDownloaderError>) -> Void) {
        let request = makeRequest(apiURL("device/info/watch"), method: .post)
        request.responseJSON { [weak self] response in
            guard let self = self else { return }
            guard response.result.isSuccess,
                  let object = response.result.value as? [String: Any] else {
                completion(.failure(self.connectionError(from: response)))
                return
            }

            guard let target = self.stringValue(object["target"]), !target.isEmpty else {
                completion(.failure(.response(self.serverMessage(from: object))))
                return
            }
            self.deviceID = target
            completion(.success(target))
        }
    }

    private func fetchDownloadFolder(completion: @escaping (Swift.Result<Void, XunleiDownloaderError>) -> Void) {
        guard let deviceID = deviceID else {
            completion(.failure(.authentication(NSLocalizedString("Could not obtain the Xunlei NAS device ID.", comment: "Xunlei authentication error"))))
            return
        }

        let filters = "{\"kind\":{\"eq\":\"drive#folder\"}}"
        let parameters: Parameters = [
            "space": deviceID,
            "limit": "200",
            "parent_id": "",
            "filters": filters,
            "page_token": "",
            "device_space": ""
        ]
        let request = makeRequest(apiURL("drive/v1/files"), method: .get, parameters: parameters)
        request.responseJSON { [weak self] response in
            guard let self = self else { return }
            guard response.result.isSuccess,
                  let object = response.result.value as? [String: Any] else {
                completion(.failure(self.connectionError(from: response)))
                return
            }

            guard let files = object["files"] as? [[String: Any]], !files.isEmpty else {
                completion(.failure(.response(NSLocalizedString("Xunlei NAS has no available download directory.", comment: "Xunlei folder error"))))
                return
            }

            let requestedName = self.configuration.xunleiDownloadDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
            let selected = requestedName.isEmpty
                ? files[0]
                : files.first { self.stringValue($0["name"]) == requestedName }

            guard let selected,
                  let folderID = self.stringValue(selected["id"]), !folderID.isEmpty else {
                let names = files.compactMap { self.stringValue($0["name"]) }.joined(separator: ", ")
                let message = String(
                    format: NSLocalizedString("Could not find Xunlei download directory \"%@\". Available directories: %@", comment: "Xunlei folder error"),
                    requestedName,
                    names
                )
                completion(.failure(.configuration(message)))
                return
            }

            self.downloadFolderID = folderID
            self.downloadFolderName = self.stringValue(selected["name"])
            completion(.success(()))
        }
    }

    // MARK: - Response parsing

    private func resource(from object: [String: Any]) throws -> XunleiResource {
        guard let list = object["list"] as? [String: Any],
              let roots = list["resources"] as? [[String: Any]],
              !roots.isEmpty else {
            throw XunleiDownloaderError.invalidResource(serverMessage(from: object))
        }

        var files: [XunleiTaskFile] = []
        var fallbackIndex = 0
        for root in roots {
            appendFiles(from: root, prefix: "", fallbackIndex: &fallbackIndex, files: &files)
        }

        guard !files.isEmpty else {
            throw XunleiDownloaderError.invalidResource(NSLocalizedString("Xunlei NAS returned no downloadable files.", comment: "Invalid Xunlei resource"))
        }

        let root = roots[0]
        let name = stringValue(root["name"]) ?? NSLocalizedString("Xunlei Task", comment: "Default Xunlei task name")
        let fileCount = intValue(root["file_count"]) ?? files.count
        return XunleiResource(name: name, fileCount: max(fileCount, files.count), files: files)
    }

    private func appendFiles(from resource: [String: Any],
                             prefix: String,
                             fallbackIndex: inout Int,
                             files: inout [XunleiTaskFile]) {
        let name = stringValue(resource["name"]) ?? NSLocalizedString("Untitled File", comment: "Fallback file name")
        let currentPath = prefix.isEmpty ? name : "\(prefix)/\(name)"
        let isDirectory = (resource["is_dir"] as? Bool == true) || resource["dir"] is [String: Any]

        if isDirectory,
           let directory = resource["dir"] as? [String: Any],
           let children = directory["resources"] as? [[String: Any]] {
            for child in children {
                appendFiles(from: child, prefix: currentPath, fallbackIndex: &fallbackIndex, files: &files)
            }
            return
        }

        let index = intValue(resource["file_index"]) ?? fallbackIndex
        let size = int64Value(resource["file_size"]) ?? 0
        files.append(XunleiTaskFile(index: index, name: currentPath, size: size))
        fallbackIndex += 1
    }

    private func isSuccessful(_ object: [String: Any]) -> Bool {
        if let status = intValue(object["HttpStatus"]) {
            return status == 0
        }
        if let errorCode = intValue(object["error_code"]) {
            return errorCode == 0
        }
        return object["task"] != nil
    }

    private func serverMessage(from object: [String: Any]) -> String {
        if let message = stringValue(object["error"]), !message.isEmpty { return message }
        if let message = stringValue(object["message"]), !message.isEmpty { return message }
        if let code = intValue(object["error_code"]) {
            return String(format: NSLocalizedString("Xunlei NAS returned error (%ld).", comment: "Xunlei server error"), code)
        }
        if let code = intValue(object["HttpStatus"]), code != 0 {
            return String(format: NSLocalizedString("Xunlei NAS returned error (%ld).", comment: "Xunlei server error"), code)
        }
        return NSLocalizedString("Xunlei NAS returned an unrecognized response.", comment: "Xunlei server error")
    }

    private func connectionError(from response: DataResponse<Any>) -> XunleiDownloaderError {
        if let statusCode = response.response?.statusCode, statusCode == 401 || statusCode == 403 {
            return .authentication(NSLocalizedString("Xunlei NAS authentication failed. Open the panel in the app to log in.", comment: "Xunlei authentication error"))
        }
        return .connection(response.result.error?.localizedDescription ?? NSLocalizedString("Could not connect to Xunlei NAS.", comment: "Xunlei connection error"))
    }

    private func connectionError(from response: DataResponse<String>) -> XunleiDownloaderError {
        if let statusCode = response.response?.statusCode, statusCode == 401 || statusCode == 403 {
            return .authentication(NSLocalizedString("Xunlei NAS authentication failed. Open the panel in the app to log in.", comment: "Xunlei authentication error"))
        }
        return .connection(response.result.error?.localizedDescription ?? NSLocalizedString("Could not connect to Xunlei NAS.", comment: "Xunlei connection error"))
    }

    // MARK: - HTTP helpers

    private func apiURL(_ endpoint: String) -> String {
        let base = serverAddress.hasSuffix("/") ? String(serverAddress.dropLast()) : serverAddress
        let suffix = endpoint.isEmpty ? "" : "/\(endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint)"
        return base + apiPrefix + suffix
    }

    private func makeRequest(_ url: String,
                             method: HTTPMethod,
                             parameters: Parameters? = nil,
                             encoding: ParameterEncoding = URLEncoding.default,
                             requiresPanAuth: Bool = true) -> DataRequest {
        var headers: HTTPHeaders = [
            "DNT": "1",
            "User-Agent": "Remote Helper/1.0",
            "device-space": "",
            "Accept": "*/*"
        ]
        if requiresPanAuth, let panAuth = panAuth {
            headers["pan-auth"] = panAuth
        }

        return Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
    }

    private func stringValue(_ value: Any?) -> String? {
        if let value = value as? String { return value }
        if let value = value as? NSNumber { return value.stringValue }
        return nil
    }

    private func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
    }

    private func int64Value(_ value: Any?) -> Int64? {
        if let value = value as? Int64 { return value }
        if let value = value as? NSNumber { return value.int64Value }
        if let value = value as? String { return Int64(value) }
        return nil
    }
}
