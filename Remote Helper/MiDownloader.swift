//
//  MiDownloader.swift
//  Remote Helper
//
//  Created by 朱文杰 on 2017/4/5.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation
import Alamofire

enum MiDownloaderProgress {
    case prepare
    case login
    case fetchDevice
    case download
}

enum MiDownloaderSuccess {
    case added
    case duplicate
    case other(Int)
}

enum MiDownloaderError: Error {
    case prepareError(String)
    case loginError(String)
    case fetchDeviceError(String)
    case downloadError(String)
}

class MiDownloader {
    var link: String
    var username: String
    var password: String

    fileprivate var base64Link: String {
        get {
            return link.base64String() ?? ""
        }
    }

    fileprivate var downloadLink: String {
        get {
            return "http://d.miwifi.com/d2r/?url=" + base64Link
        }
    }

    fileprivate var loginLink: String {
        get {
            return "https://d.miwifi.com/d2r/login?referer=" + downloadLink.percentEncodedString
        }
    }

    fileprivate let authLink = "https://account.xiaomi.com/pass/serviceLoginAuth2"
    fileprivate let confirmDownloadLink = "https://d.miwifi.com/d2r/download2RouterApi"

    init(withUsername username:String, password: String, link: String) {
        self.username = username
        self.password = password
        self.link = link
    }

    func loginAndFetchDeviceList(progress: ((MiDownloaderProgress) -> Void)? = nil, success:((MiDownloaderSuccess) -> Void)? = nil, error:((MiDownloaderError) -> Void)? = nil ) {
        Alamofire.SessionManager.default.session.reset(completionHandler: {})
        progress?(.prepare)
        Alamofire.request(loginLink).responseString {  (response) in
            progress?(.login)
            if response.result.isSuccess {
                guard let pageContent = response.result.value else { return }
                let callback = pageContent.stringByMatching("callback\\s?:\\s?\"([^\"]+)\"") ?? ""
                let qs = pageContent.stringByMatching("qs\\s?:\\s?\"([^\"]+)\"") ?? ""
                let sign = pageContent.stringByMatching("\"_sign\"\\s?:\\s?\"([^\"]+)\"") ?? ""
                let parameters: [String: Any] = ["_json":"true",
                                  "sid": "xiaoqiang_d2r",
                                  "serviceParam": "{\"checkSafePhone\":false}",
                                  "qs": qs,
                                  "callback": callback,
                                  "_sign": sign,
                                  "user": self.username,
                                  "hash": self.password.md5.uppercased()]
                Alamofire.request(self.authLink, method: .post, parameters: parameters).responseString { response in
                    progress?(.fetchDevice)
                    if response.result.isSuccess {
                        guard let responseJSON = response.result.value else { return }
                        let json = responseJSON.replacingOccurrences(of: "&&&START&&&", with: "")
                        let dict = json.JSONObject() as! [String: Any]
                        let location = dict["location"] as! String
                        Alamofire.request(location).responseString { (response) in
                            progress?(.download)
                            if response.result.isSuccess {
                                guard let html = response.result.value else { return }
                                let userId = html.stringByMatching("\"userId\"\\s?:\\s?\"([^\"]+)\"") ?? ""
                                let serviceToken = html.stringByMatching("\"serviceToken\"\\s?:\\s?\"([^\"]+)\"") ?? ""
                                let deviceId = html.stringByMatching("data-device-id=\"([^\"]+)\"") ?? ""
                                let xiaoqiang_d2r_ph = html.stringByMatching("\"xiaoqiang_d2r_ph\"\\s?:\\s?\"([^\"]+)\"") ?? ""
                                let src = html.stringByMatching("\"src\"\\s?:\\s?\"([^\"])\"") ?? ""

                                let params: [String: Any] = ["userId": userId,
                                                             "xiaoqiang_d2r_ph": xiaoqiang_d2r_ph,
                                                             "serviceToken": serviceToken,
                                                             "src": src,
                                                             "deviceId": deviceId,
                                                             "url": self.base64Link]

                                Alamofire.request(self.confirmDownloadLink, method: .post, parameters: params).responseString { response in
                                    if response.result.isSuccess {
                                        guard let text = response.result.value else { return }
                                        let result = text.JSONObject() as! [String: Any]
                                        let data = result["data"] as! [String: [[String: Any]]]
                                        if result["code"] as! Int == 0 && data["list"]![0]["errorCode"] as! Int == 0 {
                                            success?(.added)
                                        }
                                        else if result["code"] as! Int == 0 && data["list"]![0]["errorCode"] as! Int == 2010 {
                                            success?(.duplicate)
                                        }
                                        else if result["code"] as! Int == 0 {
                                            let errorCode = data["list"]![0]["errorCode"] as! Int
                                            success?(.other(errorCode))
                                        }
                                        else {
                                            error?(.downloadError(text))
                                        }
                                    }
                                    else {
                                        let err = response.result.error?.localizedDescription ?? ""
                                        error?(.downloadError(err))
                                    }
                                }
                            }
                            else {
                                let err = response.result.error?.localizedDescription ?? ""
                                error?(.fetchDeviceError(err))
                            }
                        }
                    }
                    else {
                        let err = response.result.error?.localizedDescription ?? ""
                        error?(.loginError(err))
                    }
                }
            }
            else {
                let err = response.result.error?.localizedDescription ?? ""
                error?(.prepareError(err))
            }
        }
    }

}
