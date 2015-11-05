//
//  ParseElements.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@objc
public class ParseElements : NSObject {
    public class func taskPageData(originData: String) -> [[String]] {
        let listBoxRex = "<div\\sclass=\"rw_list\"\\sid=\"\\w+\"\\staskid=\"(\\d+)\"[^>]*>([\\s\\S]+?<input\\s+id=\"openformat\\d+\"[^>]+?>)"
        let outofDateListBoxRex = "<div\\sclass=\"rw_list\"\\staskid=[\"']?(\\d+)[\"']?\\sid=[\"']?\\w+[\"']?[^>]*>([\\s\\S]+?)<input\\s+id=[\"']?d_tasktype\\d+[\"']?[^>]+?>"
        let completeTasks = originData.arrayOfCaptureComponentsMatchedByRegex(listBoxRex)
        let outOfDateTasks = originData.arrayOfCaptureComponentsMatchedByRegex(outofDateListBoxRex)
        var allTasks = completeTasks
        allTasks.appendContentsOf(outOfDateTasks)
        return allTasks
    }

    public class func taskName(taskContent: String) -> String {
        let pattern = "<span\\s+[^>]*taskid=[\"']?\\d+[\"']?[^>]*title=[\"']?([^\"]*)[\"']?.*?</span>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func taskSize(taskContent: String) -> String {
        let pattern = "<span\\s+class=\"rw_gray\"[^>]*?>([^<]+)</span>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func taskLoadProcess(taskContent: String) -> String {
        let pattern = "<em\\s+class=\"loadnum\">([^<]+)</em>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "overdue or deleted" }
        return result
    }

    public class func taskRetainDays(taskContent: String) -> String {
        let pattern = "<div\\s*class=\"sub_barinfo\">\\s*<em[^>]*>([^<]+)</em>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func taskAddTime(taskContent: String) -> String {
        let pattern = "<span\\s+class=\"c_addtime\">([^<]+)</span>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func taskDownlaodNormalURL(taskContent: String) -> String {
        let pattern = "<input\\s+id=\"dl_url\\d*\"\\s+type=\"hidden\"\\s+value=\"([^>]*)\""
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func GDriveID(taskContent: String) -> String {
        let pattern = "id=\"cok\"\\svalue=\"([^\"]+)\""
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func DCID(taskContent: String) -> String {
        let pattern = "<input\\s+id=\"dcid\\d+\".*?value=\"([^\"]*)\"\\s+/>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func taskType(taskContent: String) -> String {
        let pattern = "<input\\s+id=['\"]?openformat\\d+['\"]?.*?value=['\"]?([^'\"]+)?['\"]?\\s*/>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result //如果result结果是other就代表bt文件
    }

    public class func GCID(taskContent: String) -> String {
        let pattern = "&g=([^&]*)&"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return "unknown info" }
        return result
    }

    public class func nextPageSubURL(taskContent: String) -> String? {
        let pattern = "<li\\s*class=\"next\"><a\\s*href=\"([^\"]+)\">[^<>]*</a></li>"
        guard let result = taskContent.stringByMatching(pattern, capture:1) else { return nil }
        return result
    }

    public class func taskInfo(taskContent: String) -> [String:String] {
        var dict: [String:String] = [:]
        let pattern = "<input\\s+id=['\"]?([^0-9]+)(\\d+)['\"]?.*?value=?['\"]?([^\">]*)['\"]?"
        let data = taskContent.arrayOfCaptureComponentsMatchedByRegex(pattern)
        dict["id"] = data[0][2]
        for d in data {
            dict[d[1]] = d[3]
        }
        return dict
    }
}
