Video Player
============

一个简单的在线视频播放器，请配合[服务器端](https://github.com/venj/movie_server)一起使用。

把这个项目开源了，仅供玩耍。

新功能介绍
---------

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

已知问题
-------

- 在视频缓冲的时候，如果用户点击“Done”按钮退出播放，在某些情况下，视频依然会在后台加载并播放。


版权许可
-------

**CocoaPods打包进来的的代码不适用本协议。**

[The MIT License (MIT)](http://opensource.org/licenses/MIT)
Copyright (c) 2013 venj

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
