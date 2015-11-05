#import "HYXunleiLixianAPI.h"
#import "Video_Player-Swift.h"

@implementation HYXunleiLixianAPI

#define LoginURL @"http://login.xunlei.com/sec2login/"
#define DEFAULT_USER_AGENT  @"User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2"
#define DEFAULT_REFERER @"http://lixian.vip.xunlei.com/"

#pragma mark - BT Task
-(NSMutableArray *) readAllBTTaskListWithTaskID:(NSString *) taskid hashID:(NSString *)dcid{
    NSUInteger pg=1;
    BOOL hasNP=NO;
    NSMutableArray *allTaskArray=[NSMutableArray arrayWithCapacity:0];
    NSMutableArray *mArray=nil;
    do {
        mArray=[self readSingleBTTaskListWithTaskID:taskid hashID:dcid andPageNumber:pg];
        if(mArray){
            hasNP=YES;
            [allTaskArray addObjectsFromArray:mArray];
            pg++;
        }else{
            hasNP=NO;
        }
    } while (hasNP);
    return allTaskArray;
}
//获取BT页面内容(hashid 也就是dcid)
-(NSMutableArray *) readSingleBTTaskListWithTaskID:(NSString *) taskid hashID:(NSString *)dcid andPageNumber:(NSUInteger) pg{
    NSMutableArray *elements=[[NSMutableArray alloc] initWithCapacity:0];
    NSString *userid=[LXAPIHelper userID];
    NSString *currentTimeStamp=[LXAPIHelper currentTimeString];
    NSString *urlString=[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/fill_bt_list?callback=fill_bt_list&tid=%@&infoid=%@&g_net=1&p=%lu&uid=%@&noCacheIE=%@",taskid,dcid,(unsigned long)pg,userid,currentTimeStamp];
    NSURL *url=[NSURL URLWithString:urlString];
    //获取BT task页面内容
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSString* siteData=[request get:[url absoluteString]];
    if (siteData) {
        NSString *re=@"^fill_bt_list\\((.+)\\)\\s*$";
        NSString *s=[siteData stringByMatching:re capture:1];
        
        NSDictionary *dic=[s JSONObject];
        NSDictionary *result=[dic objectForKey:@"Result"];
        //dcid Value
        //NSString *dcid=[result objectForKey:@"Infoid"];
        NSArray *record=[result objectForKey:@"Record"];
        
        for(NSDictionary *task in record){
            XunleiItemInfo *info=[XunleiItemInfo new];

            info.taskid=taskid;
            info.name=[task objectForKey:@"title"];
            info.size=[task objectForKey:@"filesize"];
            info.retainDays=[task objectForKey:@"livetime"];
            info.addDate=@"";
            info.downloadURL=[task objectForKey:@"downurl"];
            info.originalURL=[task objectForKey:@"url"];
            info.isBT=@"1";
            info.type=[task objectForKey:@"openformat"];
            info.dcid=[task objectForKey:@"cid"];
            info.ifvod=[task objectForKey:@"vod"];
            info.status=[[task objectForKey:@"download_status"] integerValue];
            info.readableSize=[task objectForKey:@"size"];
            info.downloadPercent=[task objectForKey:@"percent"];
            [elements addObject:info];
        }
        if([elements count]>0){
            return elements;
        }else {
            return nil;
        }
    }else {
        return nil;
    }
}

#pragma mark - YunZhuanMa Methods
-(NSMutableArray*) readAllYunTasks{
    NSUInteger pg=1;
    BOOL hasNP=NO;
    NSMutableArray *allTaskArray=[NSMutableArray arrayWithCapacity:0];
    NSMutableArray *mArray=nil;
    
    do {
        mArray=[self readYunTasksWithPage:pg retIfHasNextPage:&hasNP];
        [allTaskArray addObjectsFromArray:mArray];
        pg++;
    } while (hasNP);
    return allTaskArray;
}

//获取云转码页面信息
-(NSMutableArray *) readYunTasksWithPage:(NSUInteger) pg retIfHasNextPage:(BOOL *) hasNextPageBool{
    NSString* aUserID=[LXAPIHelper userID];
    //初始化返回Array
    NSMutableArray *elements=[[NSMutableArray alloc] initWithCapacity:0];
    NSURL *requestURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/cloud?userid=%@&p=%ld",aUserID,(unsigned long)pg]];
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSString* data=[request get:[requestURL absoluteString]];
    if(data){
        if(hasNextPageBool){
            //检查是否还有下一页
            *hasNextPageBool=[self _hasNextPage:data];
        }
        NSString *re1=@"<div\\s*class=\"rwbox\"([\\s\\S]*)?<!--rwbox-->";
        NSString *tmpD1=[data stringByMatching:re1 capture:1];
        NSString *re2=@"<div\\s*class=\"rw_list\"[\\s\\S]*?<!--\\s*rw_list\\s*-->";
        NSArray *allTaskArray=[tmpD1 arrayOfCaptureComponentsMatchedByRegex:re2];
        for(NSArray *tmp in allTaskArray){
            //初始化XunleiItemInfo
            XunleiItemInfo *info=[XunleiItemInfo new];
            NSString *taskContent=[tmp objectAtIndex:0];
            
            NSMutableDictionary *taskInfoDic=[[ParseElements taskInfo:taskContent] mutableCopy];
            NSString* taskLoadingProcess=[ParseElements taskLoadProcess:taskContent];
            NSString* taskRetainDays=[ParseElements taskRetainDays:taskContent];
            NSString* taskAddTime=[ParseElements taskAddTime:taskContent];
            NSString* taskType=[ParseElements taskType:taskContent];
            NSString* taskReadableSize=[ParseElements taskSize:taskContent];
            
            info.taskid=[taskInfoDic objectForKey:@"id"];
            info.name=[taskInfoDic objectForKey:@"cloud_taskname"];
            info.size=[taskInfoDic objectForKey:@"ysfilesize"];
            info.readableSize=taskReadableSize;
            info.downloadPercent=taskLoadingProcess;
            info.retainDays=taskRetainDays;
            info.addDate=taskAddTime;
            info.downloadURL=[taskInfoDic objectForKey:@"cloud_dl_url"];
            info.type=taskType;
            info.isBT=[taskInfoDic objectForKey:@"d_tasktype"];
            info.dcid=[taskInfoDic objectForKey:@"dcid"];
            info.status=[[taskInfoDic objectForKey:@"cloud_d_status"] integerValue];
            //info.originalURL=[taskInfoDic objectForKey:@"f_url"];
            //info.ifvod=[taskInfoDic objectForKey:@"ifvod"];
            //NSLog(@"Yun Name:%@",info.name);
            [elements addObject:info];
        }
        //return info
        return elements;
    }else {
        return nil;
    }
}

#pragma mark - Add BT
//本来不想加最后那个param的。。但是貌似重复上传文件但没有后续操作会导致添加文件失败。所以就加了这个。获取数据后，把dictionary填到最后一个位置就可以了
//请注意selection的这个array里面存着的是findex

- (NSString *)addBTTask:(NSString *)filePath selection:(NSArray *)array hasFetchedFileList:(NSDictionary *)dataField {
    if (array.count > 0) {
        if (dataField == nil) {
            dataField = [self fetchBTFileList:filePath];
            if (dataField == nil) {
                return nil;
            }
        }

        int ret_value = [dataField[@"ret_value"] intValue];
        // ret value等于0就是失败啊，目前只看到出现过1，不知道会不会有别的值。所以这里先用不等于0作为判断。
        if (ret_value != 0) {
            NSString *dcid = dataField[@"infoid"];
            NSString *tsize = dataField[@"btsize"];
            NSString *btname = dataField[@"ftitle"];
            NSArray *fileList = dataField[@"filelist"];
            
            //提交任务
            NSURL *commitURL = [NSURL URLWithString:@"http://dynamic.cloud.vip.xunlei.com/interface/bt_task_commit"];
            LCHTTPConnection* commitRequest = [LCHTTPConnection new];
            
            NSArray *subSizes = [fileList valueForKey:@"subsize"];
            
            NSMutableArray *sizeArray = [[NSMutableArray alloc] init];
            for (NSString *select in array) {
                NSInteger index = [[fileList valueForKey:@"findex"] indexOfObject:select];
                [sizeArray addObject:subSizes[index]];
            }
            
            [commitRequest setPostValue:[LXAPIHelper userID] forKey:@"uid"];
            [commitRequest setPostValue:btname.percentEncodedString forKey:@"btname"];
            [commitRequest setPostValue:dcid forKey:@"cid"];
            [commitRequest setPostValue:@"0" forKey:@"goldbean"];
            [commitRequest setPostValue:@"0" forKey:@"silverbean"];
            [commitRequest setPostValue:tsize forKey:@"tsize"];
            [commitRequest setPostValue:[array componentsJoinedByString:@"_"] forKey:@"findex"];
            [commitRequest setPostValue:[sizeArray componentsJoinedByString:@"_"] forKey:@"size"];
            [commitRequest setPostValue:@"0" forKey:@"o_taskid"];
            [commitRequest setPostValue:@"task" forKey:@"o_page"];
            [commitRequest setPostValue:@"0" forKey:@"class_id"];
            [commitRequest setPostValue:@"task" forKey:@"interfrom"];
            [commitRequest post:[commitURL absoluteString]];
            return dcid;
        }
    }
    
    return nil;
}

- (NSDictionary *)fetchBTFileList:(NSString *)filePath {
    
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSString *postResult = [request postBTFile:filePath];
    
    postResult = [postResult stringByReplacingOccurrencesOfString:@"<script>document.domain=\"xunlei.com\";var btResult =" withString:@""];
    postResult = [postResult stringByReplacingOccurrencesOfString:@";var btRtcode = 0</script>" withString:@""];
    postResult = [postResult stringByReplacingOccurrencesOfString:@";</script>" withString:@""];

    if ([postResult dataUsingEncoding:NSUTF8StringEncoding] == nil) {
        return nil;
    }
    
    NSDictionary *dataField = [NSJSONSerialization JSONObjectWithData:[postResult dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error: nil];
    
    return dataField;
}

- (NSString *)fileSize:(float)size {
    int counter = 0;
    while (size > 1000) {
        size /= 1000;
        counter++;
    }
    
    NSString *size_type = @"Bytes";
    switch (counter) {
        case 1:
            size_type = @"KB";
            break;
            
        case 2:
            size_type = @"MB";
            break;
        case 3:
            size_type = @"GB";
            break;
            
        case 4:
            size_type = @"TB";
            break;
            
        case 5:
            size_type = @"PB";
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", size, size_type];
}


#pragma mark - Add Task
//add megnet task
//返回dcid作为文件标示
-(NSString *) addMegnetTask:(NSString *) url{
    NSString *dcid;
    NSString *tsize;
    NSString *btname;
    NSString *findex;
    NSString *sindex;
    NSString *enUrl=url.percentEncodedString;
    NSString *timestamp=[LXAPIHelper currentTimeString];
    NSString *callURLString=[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/url_query?callback=queryUrl&u=%@&random=%@",enUrl,timestamp];
    NSURL *callURL=[NSURL URLWithString:callURLString];
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSString* data=[request get:[callURL absoluteString]];
    NSString *re=@"queryUrl(\\(1,.*\\))\\s*$";
    NSString *sucsess=[data stringByMatching:re capture:1];
    if(sucsess){
        //NSLog(sucsess);
        NSArray *array=[sucsess componentsSeparatedByString:@"new Array"];
        //first data
        NSString *dataGroup1=[array objectAtIndex:0];
        //last data
        NSString *dataGroup2=[array objectAtIndex:([array count]-1)];
        //last fourth data
        NSString *dataGroup3=[array objectAtIndex:([array count]-4)];
        NSString *re1=@"['\"]?([^'\"]*)['\"]?";
        dcid=[[[dataGroup1 componentsSeparatedByString:@","] objectAtIndex:1] stringByMatching:re1 capture:1];
        //NSLog(cid);
        tsize=[[[dataGroup1 componentsSeparatedByString:@","] objectAtIndex:2] stringByMatching:re1 capture:1];
        //NSLog(tsize);
        btname=[[[dataGroup1 componentsSeparatedByString:@","] objectAtIndex:3] stringByMatching:re1 capture:1];
        //NSLog(btname);
        
        //findex
        NSString *re2=@"\\(([^\\)]*)\\)";
        NSString *preString0=[dataGroup2 stringByMatching:re2 capture:1];
        NSString *re3=@"'([^']*)'";
        NSArray *preArray0=[preString0 arrayOfCaptureComponentsMatchedByRegex:re3];
        NSMutableArray *preMutableArray=[NSMutableArray arrayWithCapacity:0];
        for(NSArray *a in preArray0){
            [preMutableArray addObject:[a objectAtIndex:1]];
        }
        findex=[preMutableArray componentsJoinedByString:@"_"];
        //NSLog(@"%@",findex);
        
        //size index
        preString0=[dataGroup3 stringByMatching:re2 capture:1];
        preArray0=[preString0 arrayOfCaptureComponentsMatchedByRegex:re3];
        NSMutableArray *preMutableArray1=[NSMutableArray arrayWithCapacity:0];
        for(NSArray *a in preArray0){
            [preMutableArray1 addObject:[a objectAtIndex:1]];
        }
        sindex=[preMutableArray1 componentsJoinedByString:@"_"];
        //NSLog(@"%@",sindex);
        
        //提交任务
        NSURL *commitURL = [NSURL URLWithString:@"http://dynamic.cloud.vip.xunlei.com/interface/bt_task_commit"];
        LCHTTPConnection* commitRequest = [LCHTTPConnection new];

        [commitRequest setPostValue:[LXAPIHelper userID] forKey:@"uid"];
        [commitRequest setPostValue:btname forKey:@"btname"];
        [commitRequest setPostValue:dcid forKey:@"cid"];
        [commitRequest setPostValue:tsize forKey:@"tsize"];
        [commitRequest setPostValue:findex forKey:@"findex"];
        [commitRequest setPostValue:sindex forKey:@"size"];
        [commitRequest setPostValue:@"0" forKey:@"from"];
        [commitRequest post:[commitURL absoluteString]];
    }else {
        NSString *re1=@"queryUrl\\(-1,'([^']{40})";
        dcid=[data stringByMatching:re1 capture:1];
    }
    //NSLog(@"%@",cid);
    return dcid;
}


//add normal task(http,ed2k...)
//返回dcid作为文件标示
-(NSString *) addNormalTask:(NSString *)url{
    NSString *decodeurl= [URLConverter decode:url error:nil];
    NSString *enUrl=decodeurl.percentEncodedString;
    NSString *timestamp=[LXAPIHelper currentTimeString];
    NSString *callURLString=[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/task_check?callback=queryCid&url=%@&random=%@&tcache=%@",enUrl,timestamp,timestamp];
//    NSURL *callURL=[NSURL URLWithString:callURLString];
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSString *dataRaw=[request get:callURLString];
    
    NSString *dcid=@"";
    NSString *gcid=@"";
    NSString *size=@"";
    NSString *filename=@"";
    NSString *goldbeen=@"";
    NSString *silverbeen=@"";
    NSString *is_full=@"";
    NSString *random=@"";
    NSString *ext=@"";
    NSString *someKey=@"";
    NSString *taskType=@"";
    NSString *userid=@"";
    NSString *noCacheIE = @"";
    NSString *unknownData = @"";
    
    userid=[LXAPIHelper userID];
    
    
    if(([url rangeOfString:@"http://" options:NSCaseInsensitiveSearch].length>0)||([url rangeOfString:@"ftp://" options:NSCaseInsensitiveSearch].length>0)){
        taskType=@"0";
    }else if([url rangeOfString:@"ed2k://" options:NSCaseInsensitiveSearch].length>0){
        taskType=@"2";
    }
    
    NSString *re=@"queryCid\\((.+)\\)\\s*$";
    NSString *sucsess=[dataRaw stringByMatching:re capture:1];
    NSArray *data=[sucsess componentsSeparatedByString:@","];
    NSMutableArray *newData=[NSMutableArray arrayWithCapacity:0];
    for(NSString *i in data){
        NSString *re1=@"\\s*['\"]?([^']*)['\"]?";
        NSString *d=[i stringByMatching:re1 capture:1];
        if(!d){
            d=@"";
        }
        [newData addObject:d];
        NSLog(@"%@",d);
    }
    if(8==data.count){
        dcid = newData[0];
        gcid = newData[1];
        size = newData[2];
        filename = newData[3];
        goldbeen = newData[4];
        silverbeen = newData[5];
        is_full = newData[6];
        random = newData[7];
    }
    else if(9==data.count){
        dcid = newData[0];
        gcid = newData[1];
        size = newData[2];
        filename = newData[3];
        goldbeen = newData[4];
        silverbeen = newData[5];
        is_full = newData[6];
        random = newData[7];
        ext = newData[8];
    }else if(10==data.count){
        dcid = newData[0];
        gcid = newData[1];
        size = newData[2];
        someKey = newData[3];
        filename = newData[4];
        goldbeen = newData[5];
        silverbeen = newData[6];
        is_full = newData[7];
        random = newData[8];
        ext = newData[9];
    } else if (data.count == 11) {
        dcid = newData[0];
        gcid = newData[1];
        size = newData[2];
        someKey = newData[3];
        filename = newData[4];
        goldbeen = newData[5];
        silverbeen = newData[6];
        is_full = newData[7];
        noCacheIE = newData[8];
        ext = newData[9];
        unknownData = newData[10];
    }
    //filename如果是中文放到URL中会有编码问题，需要转码
    NSString *newFilename=filename.percentEncodedString;
    
    double UTCTime=[[NSDate date] timeIntervalSince1970];
    NSString *currentTime=[NSString stringWithFormat:@"%f",UTCTime*1000];
    
    NSString *commitString1 = [NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/task_check?callback=queryCid&url=%@&interfrom=task&random=%@&tcache=%@", enUrl, currentTime,timestamp];
    
    NSString *commitString2 = [NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/task_commit?callback=ret_task&uid=%@&cid=%@&gcid=%@&size=%@&goldbean=%@&silverbean=%@&t=%@&url=%@&type=%@&o_page=history&o_taskid=0&class_id=0&database=undefined&interfrom=task&noCacheIE=%@",userid,dcid,gcid,size,goldbeen,silverbeen,newFilename,enUrl,taskType,timestamp];
    LCHTTPConnection *commitRequest1=[LCHTTPConnection new];
    [commitRequest1 get:commitString1];
    LCHTTPConnection *commitRequest2=[LCHTTPConnection new];
    [commitRequest2 get:commitString2];

    return dcid;
}

-(unsigned long long)getRandomNumberBetween:(unsigned long long)from to:(unsigned long long)to {
    
    return (unsigned long long)from + arc4random() % (to-from+1);
}

#pragma mark - Delete Task
//Delete tasks
-(BOOL) deleteSingleTaskByID:(NSString*) id{
    BOOL result=NO;
    result=[self deleteTasksByArray:@[id]];
    return result;
}
-(BOOL) deleteTasksByIDArray:(NSArray *)ids{
    BOOL result=NO;
    result=[self deleteTasksByArray:ids];
    return result;
}
-(BOOL) deleteSingleTaskByXunleiItemInfo:(XunleiItemInfo*) aInfo{
    BOOL result=NO;
    result=[self deleteTasksByArray:@[aInfo]];
    return result;
}
-(BOOL) deleteTasksByXunleiItemInfoArray:(NSArray *)ids{
    BOOL result=NO;
    result=[self deleteTasksByArray:ids];
    return result;
}
-(BOOL) deleteTasksByArray:(NSArray *)ids{
    BOOL returnResult=NO;
    NSMutableString *idString=[NSMutableString string];
    for(id i in ids){
        if([i isKindOfClass:[XunleiItemInfo class]]){
            [idString appendString:[(XunleiItemInfo*)i taskid]];
        }else if([i isKindOfClass:[NSString class]]){
            [idString appendString:i];
        }else{
            NSLog(@"Warning!!deleteTasksByArray:UnKnown Type!");
            //[idString appendString:i];
        }
        [idString appendString:@","];
    }
    NSString *jsonString=[NSString stringWithFormat:@"jsonp%@",[LXAPIHelper currentTimeString]];
    NSString *urlString=[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/task_delete?callback=%@&type=2",jsonString];
    NSLog(@"%@",urlString);
    NSURL *url=[NSURL URLWithString:urlString];
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSMutableString *IDs_postdata=[[ids componentsJoinedByString:@","] mutableCopy];
    [IDs_postdata appendString:@","];
    NSString *databasesID_postdata=@"0,";
    [request setPostValue:IDs_postdata forKey:@"taskids"];
    [request setPostValue:databasesID_postdata forKey:@"databases"];
    NSString *requestString=[request post:[url absoluteString]];
    if ([requestString hasSuffix:@"({\"result\":1,\"type\":2})"]) {
        returnResult=YES;
    }
    return returnResult;
}
#pragma mark - Pause Task
-(BOOL) pauseMultiTasksByTaskID:(NSArray*) ids{
    BOOL returnResult=NO;
    NSString* idString=[ids componentsJoinedByString:@","];
    NSString *requestString=[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/task_pause?tid=%@&uid=%@",idString,[LXAPIHelper userID]];
    LCHTTPConnection *request=[LCHTTPConnection new];
    NSString* responsed=[request get:requestString];
    if(responsed){
        returnResult=YES;
    }
    return returnResult;
}
-(BOOL) pauseTaskWithID:(NSString*) taskID{
    return [self pauseMultiTasksByTaskID:@[ taskID ]];
}
-(BOOL) pauseTask:(XunleiItemInfo*) info{
    return [self pauseTaskWithID:info.taskid];
}
-(BOOL) pauseMutiTasksByTaskItemInfo:(NSArray*) infos{
    NSMutableArray* tids=[NSMutableArray arrayWithCapacity:0];
    for(XunleiItemInfo *info in infos){
        [tids addObject:[info taskid]];
    }
    return [self pauseMultiTasksByTaskID:tids];
}
#pragma mark - ReStart Task
-(BOOL) restartTask:(XunleiItemInfo*) info{
    return [self restartMutiTasksByTaskItemInfo:@[info]];
}
-(BOOL) restartMutiTasksByTaskItemInfo:(NSArray*) infos{
    BOOL returnResult=YES;
    for(XunleiItemInfo* info in infos){
        NSString* callbackString=[NSString stringWithFormat:@"jsonp%@",[LXAPIHelper currentTimeString]];
        NSURL *requestURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://dynamic.cloud.vip.xunlei.com/interface/redownload?callback=%@",callbackString]];
        
        LCHTTPConnection* commitRequest = [LCHTTPConnection new];
        [commitRequest setPostValue:info.taskid forKey:@"id[]"];
        [commitRequest setPostValue:info.dcid forKey:@"cid[]"];
        [commitRequest setPostValue:info.originalURL forKey:@"url[]"];
        [commitRequest setPostValue:info.name forKey:@"taskname[]"];
        [commitRequest setPostValue:[NSString stringWithFormat:@"%ld",(long)info.status] forKey:@"download_status[]"];
        [commitRequest setPostValue:@"1" forKey:@"type"];
        [commitRequest setPostValue:@"0" forKey:@"class_id"];
        NSString *responseString=[commitRequest post:[requestURL absoluteString]];
        if (!responseString) {
            returnResult=NO;
        }
    }
    return returnResult;
}
@end
