//
//  XunleiItemInfo.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import Foundation

@objc
open class XunleiItemInfo : NSObject, NSCoding {
    let taskStatus = ["waiting", "downloading", "complete", "fail", "pending"]

    open var taskid: String!
    open var name: String!
    open var size: String!
    open var readableSize: String!
    open var downloadPercent: String!
    open var retainDays: String!
    open var addDate: String!
    open var downloadURL: String!
    open var originalURL: String!
    open var isBT: String!
    open var type: String!
    open var dcid: String!
    open var status: Int = 6 // statuses: Waiting = 0, Downloadding = 1, Complete = 2, Fail = 3, Pending = 4, Unknown = 5
    open var ifvod: String!

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(taskStatus[status], forKey: "status")
        aCoder.encode(self.taskid, forKey:"taskid")
        aCoder.encode(self.name, forKey:"name")
        aCoder.encode(self.size, forKey:"size")
        aCoder.encode(self.readableSize, forKey:"readableSize")
        aCoder.encode(self.downloadPercent, forKey:"loaddingProcess")
        aCoder.encode(self.retainDays, forKey:"retainDays")
        aCoder.encode(self.addDate, forKey:"addTime")
        aCoder.encode(self.downloadURL, forKey:"downloadURL")
        aCoder.encode(self.type, forKey:"type")
        aCoder.encode(self.dcid, forKey:"dcid")
        aCoder.encode(self.originalURL, forKey:"originalurl")
        aCoder.encode(self.ifvod, forKey:"ifVod")
        aCoder.encode(self.isBT, forKey:"isBT")
    }

    public required init?(coder aDecoder: NSCoder) {
        let statusString = aDecoder.decodeObject(forKey: "status") as! String
        self.status = taskStatus.index(of: statusString)!
        self.taskid = aDecoder.decodeObject(forKey: "taskid") as! String
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.size = aDecoder.decodeObject(forKey: "size") as! String
        self.downloadPercent = aDecoder.decodeObject(forKey: "loaddingProcess") as! String
        self.retainDays = aDecoder.decodeObject(forKey: "retainDays") as! String
        self.addDate = aDecoder.decodeObject(forKey: "addTime") as! String
        self.downloadURL = aDecoder.decodeObject(forKey: "downloadURL") as! String
        self.type = aDecoder.decodeObject(forKey: "type") as! String
        self.dcid = aDecoder.decodeObject(forKey: "dcid") as! String
        self.originalURL = aDecoder.decodeObject(forKey: "originalurl") as! String
        self.readableSize = aDecoder.decodeObject(forKey: "readableSize") as! String
        self.ifvod = aDecoder.decodeObject(forKey: "ifVod") as! String
        self.isBT = aDecoder.decodeObject(forKey: "isBT") as! String
    }

    public convenience override init() {
        self.init(coder:NSCoder())!
    }
}
