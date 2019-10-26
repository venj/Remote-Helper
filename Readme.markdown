# 远程下载助手

一个简单的远程下载客户端，请配合[服务器端](https://github.com/venj/movie_server)一起使用。

本项目现已完全使用 Swift Package Manager，并初步支持 Project Catalyst。

**从 v3.8 开始，客户端可以脱离服务端使用。如果没有服务端，客户端将缺少种子功能。**

先看看效果（不依赖服务端的功能）：

![动画](screenshots/preview.gif)

其他截图：

![截图](screenshots/1.png)  ![截图](screenshots/2.png)

![截图](screenshots/3.png)  ![截图](screenshots/4.png)

## 编译安装

1. 签出代码

	``` bash
	git clone https://github.com/venj/Remote-Helper.git
	```

2. 用Xcode 9.x打开`Remote Helper.xcodeproj`
3. 编译安装

## 使用说明

1. 你需要准备在电脑，服务器或者 NAS 上安装一个 Transmission，并打开远程访问。
2. 如果你有小米路由器，并开启了远程下载的话，你需要一个可用的小米账号（这不是废话吗）。
3. （可选）你需要在服务器上部署一个[服务器端](https://github.com/venj/movie_server)，并配置好爬种服务。
4. （可选）如果你有群晖 NAS，你可以在手机上安装 DS Download 客户端。

### 关于设置：

如果作为独立客户端使用，你只需要配置蓝色框中的这些选项。

![截图](screenshots/settings_example.png)

### 主要设置项说明

#### Server Settings

选项 | 作用
--- | ---
Host<sup>1</sup> | 服务端地址
Port | 服务端端口
Path | 服务端请求路径

#### Transmission Settings

选项 | 作用
--- | ---
Host<sup>2</sup> | 服务端地址(需要包括端口号，如果是特殊端口的话)
Username | Transmission远程访问用户名
Password | Transmission远程访问密码

#### Mi Remote Settings

选项 | 作用
--- | ---
Username | 小米账号用户名
Password | 小米账号密码

#### Request Settings

选项 | 作用
--- | ---
Custom UA | 服务端的自定义User-Agent
Use SSL | 服务端地址是否配置了 HTTPS
Allow Use Cellular Network | 允许手机网络下使用

备注

1. 如果不配合服务端使用，服务器设置部分的 Host 保持默认（或设置为4个字符以下的任意内容）。
2. Transmission 设置部分的地址必须包含端口，别问我为什么没有把端口单独作为选项列出来😓。

其他配置项不重要，就不一一说明了。

## 新功能介绍

**4.0**

- 远程助手现已可以通过 Project Catalyst 支持 macOS。

**3.8**

一大波新特征...

- 网页链接列表支持 Peek
- 网址链接列表现已使用Core Data存储
- 网址链接列表支持iOS 11的拖放链接（iPad）
- 种子喵搜索
- 种子列表支持存储已读状态
- 种子列表显示图片数量（需要最新版服务端支持）
- iCloud同步种子列表阅读状态
- 加入电影天堂板块
- 移除迅雷离线支持
- 增加小米远程支持
- 适配了新的iOS API
- 再次支持 iOS 8+
- 源码使用 Swift 4 编写

(中间忽略大量更新日志...)

**2.0 (???)**

- 没有新特征！！！
- 源码除了部分第三方库，全面Swift化

**1.5 (172)**

- 加入蜂窝数据使用控制
- iPhone 6S的Force Touch桌面菜单（然并卵）
- iOS 9多任务支持
- 群晖Download Station整合
- Web内容下载链接解析

**1.5 (132)**

- 加入SSL支持；
- 加入自定义浏览器标识设置；
- 大量bug修正；

**1.5 (96)**

- 将网络请求超时减少至10秒；
- 修正了Loading HUD阻断全屏点击的问题；
- 用图标替代工具栏按钮文字。

**1.4 (95)**

- 新增浏览图片缓存功能。

**1.3 (91)**

- 升级了程序使用的库。
- 新增复制Magnet链接功能（需要最新版Movie Player服务器支持）。

**1.2 (85)**

- 升级了程序使用的库。
- iOS 7兼容。
- BlocksKit的`AlertView`扩展导致程序崩溃的Bug已修正。
- 修正了MWPhotoBrowser的回调无法正常调用的Bug。

**1.1.2 (70)**

- 现在，不返回下载实际大小的视频文件也能正常显示百分比进度了。

**1.1.1 Build 69**

- 种子浏览可以自己制定初始ID。

**1.1 Build 65**

- 修正了播放视频时锁屏后，导致视频无法再次播放的问题。
- 增加了大量文档注释（跟App没啥关系）。

**1.1 Build 64**

- 修正了Spotlight图标错误。

**1.1 Build 63**

- 增加服务器上文件已删除的提示（需要服务器v0.0.2配合使用）。

**1.1 Build 60**

- 新图标！

**1.1 Build 59**

- 视频下载时进入后台后，系统将继续下载。当后台任务超时被系统杀死的时候，会执行清理工作。

**1.1 Build 57**

- 改进下载功能的错误处理。
- 当下载文件长度未知的时候，显示下载大小作为提示。

**1.1 Build 56**

- 改进了局域网变化的提示框显示的时机。
- 下载视频时，设备不会睡眠。
- 网段变化时，种子列表初次加载不再出现提示框，除非用户刷新。
- 改进直接播放已经下载过的网络视频功能。

**1.1 Build 54**

- 新的版本号1.1，yeah～
- 可以把服务器上的文件下载到本地（目前仅限下载功能，甚至不能终端下载）。
- 设置中可以查看本地视频大小与设备剩余空间。
- 已经下载过的网络视频，会直接播放本地视频而不走网络流量。

**1.0 Build 50**

- 修正了在使用域名作为服务器设置（比如，mDNS的xxx.local这样的地址）时，无法连接服务器的问题。

**1.0 Build 43**

- 汉化了云端下载状态。
- 修正了一个AirPlay时视频播放会因为系统睡眠而中断的问题。
- 加载种子浏览页面时增加HUD，显示加载进度圈。

**1.0 Build 42**

- 稍微调整了iPad下删除按钮的长度。
- 增加了简体中文翻译，因为KKPasscode控件不支持本地化，因此目前密码设置依然是英文界面。
- 改进了文件大小显示（支持B，KB，MB，GB为单位，进制为1024）。

**1.0 Build 41**

- 重构代码，让本地文件和远程文件使用统一个ViewController来呈现。
- 修正了iPad下，本地文件信息没有先是在右半侧界面中的问题。

**1.0 Build 40**

- 将BT列表整合进Tabbar（iPhone），iPad依然使用Modal显示BT列表。

**1.0 Build 39**

- 改善iPad支持。

**1.0 Build 38**

- 将密码锁设置功能整合进Settings。
- 修正了在视频播放时锁屏后，解锁iOS设备，程序无法启动密码界面的问题。

**1.0 Build 37**

- 为本地视频增加跳过备份的文件属性以防止iTunes备份本地视频。

**1.0 Build 36**

- 加入了本地视频播放功能。

**1.0 Build 31**

- 修正了在ActionSheet呈现时锁定App，解锁后ActionSheet无法自动隐藏的问题。

**1.0 Build 30**

- 在视频信息页面增加删除按钮，可以快速删除服务器上的文件（请谨慎使用，以防误删）。需要最新版服务器端支持。

**1.0 Build 29**

- 在网络错误提示面板加入直接调出“设置”的按钮。

**1.0 Build 28**

- 加入同步和异步添加离线任务支持（需要最新版服务器端支持）。

**1.0 Build 27**

- 当iOS设备与服务器不在同一个网络中的时候（仅限C类地址），程序将不会尝试连接服务器，而是直接给出一个错误提示。

**1.0 Build 26**

- 在种子日期列表中加入搜索功能，用于过滤日期。

**1.0 Build 25**

- 在载入种子日期列表的时候，使用了加载进度显示；
- 修正了一个导致密码界面无法显示的问题（通过隐藏位于最前端的ModalViewController，并不是一个好方法，但目前只能这么解决。）

**1.0 Build 24**

- 为程序增加密码锁定功能，注意事项如下：
    + 清除数据开关实际上并没有起作用
    + 如果你输错了5次密码，程序将锁住。这时候，请按Home键退出，然后双击Home键，在任务列表里杀死进程后重新打开程序
    + 如果应用程序位于后台（并没有被杀死的时候）再次打开程序可能会出现之前浏览的画面大约0.?秒
    + 密码锁以全屏Modal的方式在iPad上显示，用来避免程序主界面无法被完全覆盖

## 版权许可

[The MIT License (MIT)](http://opensource.org/licenses/MIT)
Copyright (c) 2013 venj

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
