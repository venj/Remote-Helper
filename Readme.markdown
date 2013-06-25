Video Player
============

Simple video player which aim to become a full functional management client for my Cubieboard.

What's New
----------

**1.0 Build 25**

- Added loading HUD for Gallary
- Fixed a bug prevent showing passcode UI (by dismiss any modal include gallary, not a good way, but works.)

**1.0 Build 24**

- Added Passcode for the app.
    + Erase data actually does nothing to your data
    + If you used out all 5 attempt for the password, you should kill the app and retry
    + If you app is on background, activate it will show a flash of your content
    + Passcode input showed on full screen on iPad, because the app load content before password check, full screen will prevent reveal the app content
- Known bug: When the movie is loading from the web, and user quit the playing screen, some times video will still play in the background.
