//
//  LXAPIHelper.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/5.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

let CookieDomainSuffix = ".xunlei.com"
let LoginURL = "http://login.xunlei.com/sec2login/"
let DEFAULT_USER_AGENT = "User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2"
let DEFAULT_REFERER = "http://lixian.vip.xunlei.com/"

class LXAPIHelper : NSObject {
    //MARK: - General Helper
    // Time Stamp String
    class func currentTimeString() -> String {
        let UTCTime = NSDate().timeIntervalSince1970
        let currentTime = String(format:"%f", arguments: [UTCTime * 1000])
        return currentTime.componentsSeparatedByString(".")[0]
    }

    //MARK: - Cookie Helper
    // Make cookie string and set as HTTPRequest header.
    class func refreshCookie(forRequest request:NSMutableURLRequest) {
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        var cookieString = ""
        for cookie in cookieStorage.cookies! {
            if cookie.domain.hasSuffix(CookieDomainSuffix) {
                cookieString += "\(cookie.name)=\(cookie.value); "
            }
        }
        request.setValue(cookieString, forHTTPHeaderField: "Cookie")
    }

    // Add a cookie to storage and return.
    class func setCookie(withKey key:String, value:String) -> NSHTTPCookie {
        var properties:[String: AnyObject] = [:]
        properties[NSHTTPCookieValue] = value
        properties[NSHTTPCookieName] = key
        properties[NSHTTPCookieDomain] = ".vip.xunlei.com"
        properties[NSHTTPCookiePath] = "/"
        properties[NSHTTPCookieExpires] = NSDate(timeIntervalSinceNow: 2629743)
        let cookie = NSHTTPCookie(properties: properties)
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        cookieStorage.cookieAcceptPolicy = .Always
        cookieStorage.setCookie(cookie!)
        // Removed add to responseCookies
        return cookie!
    }

    // Get cookie value by name
    class func cookieValue(withName name:String) -> String? {
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        guard let cookies = cookieStorage.cookies else { return nil }
        var value: String? = nil
        for cookie in cookies {
            if cookie.domain.hasSuffix(CookieDomainSuffix) && cookie.name == name {
                value = cookie.value
                break
            }
        }
        return value
    }

    class func hasCookie(name:String) -> Bool {
        return cookieValue(withName: name) != nil ? true : false
    }

    //MARK: - UserID and UserName
    class func userID() -> String {
        guard let uid = cookieValue(withName: "userid") else { return "" }
        return uid
    }

    class func userName() -> String {
        guard let name = cookieValue(withName: "usernewno") else { return "" }
        return name
    }

    class func encodePassword(password: String, withVerifyCode code: String) -> String {
        return ("\(password.md5.md5)\(code.uppercaseString)".md5)
    }

    //MARK: - Referer
    // TODO: Remove me after migration
    @objc(refererWithStringFormat)
    class func refererString() -> String {
        return "http://dynamic.cloud.vip.xunlei.com/user_task?userid=\(userID())"
    }

    // TODO: Remove me after migration
    @objc(refererWithURLFormat)
    class func refererURL() -> NSURL {
        return NSURL(string: refererString())!
    }

    //MARK: - GDriveID
    class func GDriveID() -> String? {
        return cookieValue(withName: "gdriveid")
    }

    class func isGDriveIDInCookie() -> Bool {
        return (GDriveID() != nil)
    }

    class func setGdriveID(id: String) {
        setCookie(withKey: "gdriveid", value: id)
    }

    // MARK: - Login and logout
    class func logout() {
        let keys = ["vip_isvip","lx_sessionid","vip_level","lx_login","dl_enable","in_xl","ucid","lixian_section","sessionid","usrname","nickname","usernewno","userid","gdriveid"]
        for key in keys {
            setCookie(withKey: key, value: "")
        }
    }

    class func login(withUsername name: String, password: String, encoded:Bool) -> Bool {
        guard let code = verifyCode(withUserName: name) else { return false }
        let encodedPassword = encoded ? "\(password)\(code.uppercaseString)".md5 : encodePassword(password, withVerifyCode: code)
        let connection = LCHTTPConnection.sharedConnection
        let url = NSURL(string: LoginURL)!
        connection.set(PostValue: name, forKey: "u")
        connection.set(PostValue: encodedPassword, forKey: "p")
        connection.set(PostValue: code, forKey: "verifycode")
        connection.set(PostValue: "0", forKey: "login_enable")
        connection.set(PostValue: "720", forKey: "login_hour")
        connection.post(url.absoluteString)
        let timeStamp = LXAPIHelper.currentTimeString()
        let redirectURLString = "http://dynamic.lixian.vip.xunlei.com/login?cachetime=\(timeStamp)&from=0"
        let redirectConnection = LCHTTPConnection.sharedConnection
        guard let html = redirectConnection.get(redirectURLString) else { return false }
        let pattern = "id=\"cok\" value=\"([^\"]+)\""
        guard let s = html.stringByMatching(pattern) else { return false }
        setGdriveID(s)
        return  userID().characters.count > 1
    }

    // Get login verify code.
    class func verifyCode(withUserName name: String) -> String? {
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        cookieStorage.cookieAcceptPolicy = .Always
        let checkURLString = "http://login.xunlei.com/check?u=\(name)&cachetime=\(currentTimeString())"
        let request = LCHTTPConnection.sharedConnection
        request.get(checkURLString)
        guard let verifyCode = cookieValue(withName: "check_result") else { return nil }
        if verifyCode.rangeOfString(":") != nil {
            return verifyCode.componentsSeparatedByString(":")[1]
        }
        else {
            return nil
        }
    }

    //MARK: - Request Helper
    class func send(syncRequest request: NSMutableURLRequest) -> String? {
        var urlResponse: NSURLResponse? = nil // should be exactly like this!!!
        do {
            let responseData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &urlResponse)
            let responseString = String(data: responseData, encoding: NSUTF8StringEncoding)
            guard let response = urlResponse as? NSHTTPURLResponse else { return nil }
            if (response.allHeaderFields["Set-Cookie"] != nil) {
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(response.allHeaderFields as! [String:String], forURL: NSURL(string: ".vip.xunlei.com")!)
                for cookie in cookies {
                    setCookie(withKey: cookie.name, value: cookie.value)
                }
            }
            let statusCode = response.statusCode
            if statusCode >= 200 && statusCode < 400 {
                return responseString
            }
            else { // Error
                print("Error status: \(statusCode), \(NSHTTPURLResponse.localizedStringForStatusCode(statusCode))")
            }
        }
        catch let error as NSError {
            print("Network error: \(error.localizedDescription)")
        }
        return nil
    }

    class func addMegnetTask(magnet: String) -> String {
        var tsize = "", btname = "", findex = "", sindex = ""

        let encodedURLString = magnet.percentEncodedString
        let timeStamp = currentTimeString()
        let callURLString = "http://dynamic.cloud.vip.xunlei.com/interface/url_query?callback=queryUrl&u=\(encodedURLString)&random=\(timeStamp)"
        let data = LCHTTPConnection.sharedConnection.get(callURLString)
        let re = "queryUrl(\\(1,.*\\))\\s*$"
        let success = data?.stringByMatching(re)
        if success != nil {
            let array = success!.componentsSeparatedByString("new Array")
            let dataGroup1 = array[0]
            let dataGroup2 = array[array.count - 1]
            let dataGroup3 = array[array.count - 4]
            let re1 = "['\"]?([^'\"]*)['\"]?"
            let dcid = dataGroup1.componentsSeparatedByString(",")[1].stringByMatching(re1)!
            tsize = dataGroup1.componentsSeparatedByString(",")[2].stringByMatching(re1)!
            btname = dataGroup1.componentsSeparatedByString(",")[3].stringByMatching(re1)!
            let re2 = "\\(([^\\)]*)\\)"
            var preString0 = dataGroup2.stringByMatching(re2)!
            let re3 = "'([^']*)'"
            var preArray0 = preString0.arrayOfCaptureComponentsMatchedByRegex(re3)
            var preMArray:[String] = []
            for a in preArray0 {
                if a.count < 2 { continue }
                preMArray.append(a[1])
            }
            findex = preMArray.joinWithSeparator("_")

            preString0 = dataGroup3.stringByMatching(re2)!
            preArray0 = preString0.arrayOfCaptureComponentsMatchedByRegex(re3)
            var preMArray1:[String] = []
            for a in preArray0 {
                if a.count < 2 { continue }
                preMArray1.append(a[1])
            }
            sindex = preMArray1.joinWithSeparator("_")

            let commitConnection = LCHTTPConnection.sharedConnection
            commitConnection.set(PostValue: userID(), forKey: "uid")
            commitConnection.set(PostValue:btname, forKey:"btname")
            commitConnection.set(PostValue:dcid, forKey:"cid")
            commitConnection.set(PostValue:tsize, forKey:"tsize")
            commitConnection.set(PostValue:findex, forKey:"findex")
            commitConnection.set(PostValue:sindex, forKey:"size")
            commitConnection.set(PostValue:"0", forKey:"from")
            commitConnection.post("http://dynamic.cloud.vip.xunlei.com/interface/bt_task_commit")
            return dcid
        }
        else {
            let ptn = "queryUrl\\(-1,'([^']{40})"
            let dcid = data!.stringByMatching(ptn)
            return dcid!
        }
    }

    class func addOldMegnetTask(magnet: String) -> String {
        let encodedMagnet = magnet.percentEncodedString
        let timeStamp = currentTimeString()
        let callURLString = "http://dynamic.cloud.vip.xunlei.com/interface/url_query?callback=queryUrl&u=\(encodedMagnet)&random=\(timeStamp)"
        let url = NSURL(string: callURLString)
        let connection = LCHTTPConnection.sharedConnection
        guard let html = connection.get(url!.absoluteString) else { return "" }
        let pattern = "queryUrl(\\(1,.*\\))\\s*$"
        let successContent = html.stringByMatching(pattern)
        if successContent != nil {
            let arrayContent = successContent!.componentsSeparatedByString("new Array")
            let dataGroup1 = arrayContent[0]
            let dataGroup2 = arrayContent[arrayContent.count - 1]
            let dataGroup3 = arrayContent[arrayContent.count - 4]
            let pattern1 = "['\"]?([^'\"]*)['\"]?"
            let parts1 = dataGroup1.componentsSeparatedByString(",")
            let dcid = parts1[1].stringByMatching(pattern1)
            let tsize = parts1[2].stringByMatching(pattern1)
            let btname = parts1[3].stringByMatching(pattern1)
            let pattern2 = "\\(([^\\)]*)\\)"
            var matchedString = dataGroup2.stringByMatching(pattern2)
            let pattern3 = "'([^']*)'"
            let parts2 = matchedString!.arrayOfCaptureComponentsMatchedByRegex(pattern3)
            var indexes:[String] = []
            for part in parts2 {
                indexes.append(part[1])
            }
            let findex = indexes.joinWithSeparator("_")

            matchedString = dataGroup3.stringByMatching(pattern2)
            let parts3 = matchedString!.arrayOfCaptureComponentsMatchedByRegex(pattern3)
            indexes = []
            for part in parts3 {
                indexes.append(part[1])
            }
            let sindex = indexes.joinWithSeparator("_")

            let commitConnection = LCHTTPConnection.sharedConnection
            commitConnection.set(PostValue: userID(), forKey: "uid")
            commitConnection.set(PostValue:btname!, forKey:"btname")
            commitConnection.set(PostValue:dcid!, forKey:"cid")
            commitConnection.set(PostValue:tsize!, forKey:"tsize")
            commitConnection.set(PostValue:findex, forKey:"findex")
            commitConnection.set(PostValue:sindex, forKey:"size")
            commitConnection.set(PostValue:"0", forKey:"from")
            commitConnection.post("http://dynamic.cloud.vip.xunlei.com/interface/bt_task_commit")
            return dcid!
        }
        else {
            let ptn = "queryUrl\\(-1,'([^']{40})"
            let dcid = html.stringByMatching(ptn)
            return dcid!
        }
    }

    class func addNormalTask(urlString: String) -> String {
        guard let decodedURLString = try? URLConverter.decode(urlString) else { return "" }
        let encodedURLString = decodedURLString.percentEncodedString
        let timeStamp = currentTimeString()
        let callURLString = "http://dynamic.cloud.vip.xunlei.com/interface/task_check?callback=queryCid&url=\(encodedURLString)&random=\(timeStamp)&tcache=\(timeStamp)"
        let connection = LCHTTPConnection.sharedConnection
        let html = connection.get(callURLString)
        let uid = userID()
        var taskType: String = ""
        if urlString.lowercaseString.rangeOfString("http://") != nil || urlString.lowercaseString.rangeOfString("https://") != nil || urlString.lowercaseString.rangeOfString("ftp://") != nil {
            taskType = "0"
        }
        else if urlString.lowercaseString.rangeOfString("ed2k://") != nil {
            taskType = "2"
        }

        let pattern = "queryCid\\((.+)\\)\\s*$"
        let success = html!.stringByMatching(pattern)
        let data = success!.componentsSeparatedByString(",")
        var newData: [String] = []
        for i in data {
            let pattern1 = "\\s*['\"]?([^']*)['\"]?"
            var d = i.stringByMatching(pattern1)
            if d == nil {
                d = ""
            }
            newData.append(d!)
        }

        var dcid = "", gcid = "", size = "", filename = "", goldbean = ""
        var silverbean = ""

        // Common
        dcid = newData[0]
        gcid = newData[1]
        size = newData[2]
        if data.count == 8 {
            filename = newData[3]
            goldbean = newData[4]
            silverbean = newData[5]
        }
        else if data.count == 9 {
            filename = newData[3]
            goldbean = newData[4]
            silverbean = newData[5]
        }
        else if data.count == 10 {
            filename = newData[4]
            goldbean = newData[5]
            silverbean = newData[6]
        }
        else if data.count == 11 {
            filename = newData[4]
            goldbean = newData[5]
            silverbean = newData[6]
        }

        let newFilename = filename.percentEncodedString
        let ts = NSDate().timeIntervalSince1970 * 1000
        let timeString = String(format: "%f", arguments: [ts])
        let commitString1 = "http://dynamic.cloud.vip.xunlei.com/interface/task_check?callback=queryCid&url=\(encodedURLString)&interfrom=task&random=\(timeString)&tcache=\(timeStamp)"
        let commitString2 = "http://dynamic.cloud.vip.xunlei.com/interface/task_commit?callback=ret_task&uid=\(uid)&cid=\(dcid)&gcid=\(gcid)&size=\(size)&goldbean=\(goldbean)&silverbean=\(silverbean)&t=\(newFilename)&url=\(encodedURLString)&type=\(taskType)&o_page=history&o_taskid=0&class_id=0&database=undefined&interfrom=task&noCacheIE=\(timeStamp)"
        LCHTTPConnection.sharedConnection.get(commitString1)
        LCHTTPConnection.sharedConnection.get(commitString2)
        return dcid
    }
}