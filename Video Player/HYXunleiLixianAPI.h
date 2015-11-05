//
//  HWXunleiLixianAPI.h
//  XunleiLixian-API
//
//  Created by Liu Chao on 6/10/12.
//  Copyright (c) 2012 HwaYing. All rights reserved.
//
/*This file is part of XunleiLixian-API.
 
 XunleiLixian-API is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 XunleiLixian-API is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
@class XunleiItemInfo;

@interface HYXunleiLixianAPI : NSObject
-(XunleiItemInfo *) getTaskWithTaskID:(NSString*) aTaskID;

#pragma mark - Task
//获得不同下载状态的任务列表
-(NSMutableArray*) readAllTasks1;
-(NSMutableArray*) readTasksWithPage:(NSUInteger) pg;
-(NSMutableArray*) readAllCompleteTasks;
-(NSMutableArray*) readCompleteTasksWithPage:(NSUInteger) pg;

-(NSMutableArray*) readAllDownloadingTasks;
-(NSMutableArray*) readDownloadingTasksWithPage:(NSUInteger) pg;
/* //Some Problems Tempremoved*/
-(NSMutableArray *) readAllOutofDateTasks;
-(NSMutableArray *) readOutofDateTasksWithPage:(NSUInteger) pg;

-(NSMutableArray*) readAllDeletedTasks;
-(NSMutableArray*) readDeletedTasksWithPage:(NSUInteger) pg;

#pragma mark - BT Task
//BT任务列表
-(NSMutableArray *) readSingleBTTaskListWithTaskID:(NSString *) taskid hashID:(NSString *)dcid andPageNumber:(NSUInteger) pg;
-(NSMutableArray *) readAllBTTaskListWithTaskID:(NSString *) taskid hashID:(NSString *)dcid;
#pragma mark - Add Task
//添加任务
-(NSString *) addMegnetTask:(NSString *) url;
-(NSString *) addNormalTask:(NSString *)url;
#pragma mark - Delete Task
//删除任务
-(BOOL) deleteTasksByIDArray:(NSArray *)ids;
-(BOOL) deleteSingleTaskByID:(NSString*) id;
-(BOOL) deleteSingleTaskByXunleiItemInfo:(XunleiItemInfo*) aInfo;
-(BOOL) deleteTasksByXunleiItemInfoArray:(NSArray *)ids;
#pragma mark - Pause Task
-(BOOL) pauseMultiTasksByTaskID:(NSArray*) ids;
-(BOOL) pauseTaskWithID:(NSString*) taskID;
-(BOOL) pauseTask:(XunleiItemInfo*) info;
-(BOOL) pauseMutiTasksByTaskItemInfo:(NSArray*) infos;
#pragma mark - ReStart Task
-(BOOL) restartTask:(XunleiItemInfo*) info;
-(BOOL) restartMutiTasksByTaskItemInfo:(NSArray*) infos;
#pragma mark - Rename Task
// 添加BT任务
- (NSString *)addBTTask:(NSString *)filePath selection:(NSArray *)array hasFetchedFileList:(NSDictionary *)dataField;
- (NSDictionary *)fetchBTFileList:(NSString *)filePath;
- (NSString *)fileSize:(float)size; //一个根据length返回文件大小的方法

@end
