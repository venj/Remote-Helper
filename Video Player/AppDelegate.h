//
//  AppDelegate.h
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#define REQUEST_TIME_OUT 10.
#import "HYXunleiLixianAPI.h"

@class WebContentTableViewController, AFHTTPSessionManager;

/*!
 @class AppDelegate
 @brief The application delegate for current App.
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) WebContentTableViewController *fileListViewController;
// Record Xunlei login status for app life cycle
@property (nonatomic, assign, getter=isXunleiUserLoggedIn) BOOL xunleiUserLoggedIn;
/*!
 @brief Return the AppDelegate singleton for sharing data and states between View Controllers.
 @return The AppDelegate singleton.
 */
+ (AppDelegate *)shared;
+ (HYXunleiLixianAPI *)sharedAPI;
/*!
 @brief Passed in a file relative path to get the remote link for the path.
 @param path Specify a relative path.
 @return Absolute remote link for the file.
 */
- (NSString *)fileLinkWithPath:(NSString *)path;

/*!
 @brief Compose a remote link for common file operations.
 @param operation Specify the file operation, like <code>delete</code> for delete a remote file; <code>info</code> for get file stat info.
 @param path The path for web application. In most cases, it is <code>/</code>.
 @param fileName Specify the file name which actually a relative path to the file.
 @return Absolute remote link for file operations.
 */
- (NSString *)fileOperation:(NSString *)operation withPath:(NSString *)path fileName:(NSString *)fileName;

/*!
 @brief Read Transmission server address from settings.
 @return The Transmission web interface address.
 */
- (NSString *)getTransmissionServerAddress;
- (NSString *)getTransmissionServerAddressWithUserNameAndPassword:(BOOL)withUserNameAndPassword;
- (NSString *)getTransmissionRPCAddress;

/*!
 @brief Read username and password for Transmission web interface.
 @return An array with username and password.
*/
- (NSArray *)getUsernameAndPassword;
/*!
 @brief Read username and password for Xunlei lixian.
 @return An array with username and password.
 */
- (NSArray *)getXunleiUsernameAndPassword;
/*!
 @brief Compose a remote link for torrents date list according to user server settings.
 @return Absolute remote link for torrents date list.
 */
- (NSString *)torrentsListPath;
/*!
 @brief Compose a remote link for search torrent db.
 @param keyword Keyword for search.
 @return Absolute remote link for search torrent db.
 */
- (NSString *)dbSearchPathWithKeyword:(NSString *)keyword;
/*!
 @brief Compose a remote link for search file names include some keyword.
 @param keywork The keyword to search for.
 @return Absolute remote link for search operation.
 */
- (NSString *)searchPathWithKeyword:(NSString *)keyword;

/*!
 @brief Compose a remote link to add a torrent file to Cloud download.
 @param name The image file name (a relative path) associated with a torrent file.
 @param async This param is used to let the application waits for add torrent result or not.
 @return Absolute remote link for add a torrent.
 */
- (NSString *)addTorrentWithName:(NSString *)name async:(BOOL)async;

/*!
 @brief Compose a remote link to hash a torrent file.
 @param name The image file name (a relative path) associated with a torrent file.
 @return Absolute remote link for hash a torrent.
 */
- (NSString *)hashTorrentWithName:(NSString *)name;

/*!
 @brief According to the current IP address and server configuration, if the device is not in the same LAN as the server, app will not send web request to the server.
 @return Returns <code>YES</code> if server and client are in the same LAN, <code>NO</code> for otherwise.
 */
- (BOOL)shouldSendWebRequest;

/*!
 @brief Get the user's Documents directory inside app sandbox.
 @return The absolute path to user's Documents directory.
 */
- (NSString *)documentsDirectory;

/*!
 @brief Get the free disk space size for the current device.
 @return Returns the <code>unsigned long long</code> value in bytes for free disk space. 
 */
- (uint64_t)freeDiskSpace;

/*!
 @brief Get the total file size inside user's Documents directory.
 @return Returns the <code>unsigned long long</code> value in bytes for file size.
 */
- (uint64_t)localFileSize;

/*!
 @brief Use the bytes value to get a string representation for the file with appropreate unit, calculated in 1024-base.
 @param size Size in bytes
 @return String representation for a file size. e.g. 255.1 MB, 1.1GB
 */
- (NSString *)fileSizeStringWithInteger:(uint64_t)size;

/*!
 @brief Compose a remote link for a remote file to download.
 @param path The relative path for the file to download.
 @return The absolute path to the server for the file to download.
 */
- (NSString *)fileToDownloadWithPath:(NSString *)path;

/*!
 @brief Get the video play url according the the relative path. If the remote file is downloaded, it will return an <code>NSURL</code> for local file path.
 @param path The relative path for the video to be played.
 @return An <code>NSURL</code> object for a local file or a remote address.
 */
- (AFHTTPSessionManager *)refreshedManagerWithAuthentication:(BOOL)withAuth;
- (AFHTTPSessionManager *)refreshedManager;
- (void)showTorrentSearchAlertInNavigationController:(UINavigationController *)navigationController;
- (void)showHudWithMessage:(NSString *)message inView:(UIView *)aView;
- (NSURL *)videoPlayURLWithPath:(NSString *)path;
- (void)parseSessionAndAddTask:(NSString *)magnet completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler;
- (NSString *)customUserAgent;
- (BOOL)useSSL;
@end
