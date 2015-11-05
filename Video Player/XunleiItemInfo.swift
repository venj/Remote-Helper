//
//  XunleiItemInfo.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@objc
public class XunleiItemInfo : NSObject, NSCoding {
    let taskStatus = ["waiting", "downloading", "complete", "fail", "pending"]

    public var taskid: String!
    public var name: String!
    public var size: String!
    public var readableSize: String!
    public var downloadPercent: String!
    public var retainDays: String!
    public var addDate: String!
    public var downloadURL: String!
    public var originalURL: String!
    public var isBT: String!
    public var type: String!
    public var dcid: String!
    public var status: Int = 6 // statuses: Waiting = 0, Downloadding = 1, Complete = 2, Fail = 3, Pending = 4, Unknown = 5
    public var ifvod: String!

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(taskStatus[status], forKey: "status")
        aCoder.encodeObject(self.taskid, forKey:"taskid")
        aCoder.encodeObject(self.name, forKey:"name")
        aCoder.encodeObject(self.size, forKey:"size")
        aCoder.encodeObject(self.readableSize, forKey:"readableSize")
        aCoder.encodeObject(self.downloadPercent, forKey:"loaddingProcess")
        aCoder.encodeObject(self.retainDays, forKey:"retainDays")
        aCoder.encodeObject(self.addDate, forKey:"addTime")
        aCoder.encodeObject(self.downloadURL, forKey:"downloadURL")
        aCoder.encodeObject(self.type, forKey:"type")
        aCoder.encodeObject(self.dcid, forKey:"dcid")
        aCoder.encodeObject(self.originalURL, forKey:"originalurl")
        aCoder.encodeObject(self.ifvod, forKey:"ifVod")
        aCoder.encodeObject(self.isBT, forKey:"isBT")
    }

    public required init?(coder aDecoder: NSCoder) {
        let statusString = aDecoder.decodeObjectForKey("status") as! String
        self.status = taskStatus.indexOf(statusString)!
        self.taskid = aDecoder.decodeObjectForKey("taskid") as! String
        self.name = aDecoder.decodeObjectForKey("name") as! String
        self.size = aDecoder.decodeObjectForKey("size") as! String
        self.downloadPercent = aDecoder.decodeObjectForKey("loaddingProcess") as! String
        self.retainDays = aDecoder.decodeObjectForKey("retainDays") as! String
        self.addDate = aDecoder.decodeObjectForKey("addTime") as! String
        self.downloadURL = aDecoder.decodeObjectForKey("downloadURL") as! String
        self.type = aDecoder.decodeObjectForKey("type") as! String
        self.dcid = aDecoder.decodeObjectForKey("dcid") as! String
        self.originalURL = aDecoder.decodeObjectForKey("originalurl") as! String
        self.readableSize = aDecoder.decodeObjectForKey("readableSize") as! String
        self.ifvod = aDecoder.decodeObjectForKey("ifVod") as! String
        self.isBT = aDecoder.decodeObjectForKey("isBT") as! String
    }

    public convenience override init() {
        self.init(coder:NSCoder())!
    }
}
