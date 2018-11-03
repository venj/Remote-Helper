//
//  UIImage+BarButtomItemIcon.swift
//  Remote Helper
//
//  Created by venj on 10/19/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

@objc 
extension UIImage {
    static func backButtonIcon() -> UIImage {
        var backButtonImage: UIImage

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 12.0, height: 21.0), false, UIScreen.main.scale)

        let backColor = UIColor.black
        let backButtonPath = UIBezierPath()
        backButtonPath.move(to: CGPoint(x: 10.9, y: 0.0))
        backButtonPath.addLine(to: CGPoint(x: 12.0, y: 1.1))
        backButtonPath.addLine(to: CGPoint(x: 1.1, y: 11.75))
        backButtonPath.addLine(to: CGPoint(x: 0.0, y: 10.7))
        backButtonPath.addLine(to: CGPoint(x: 10.9, y: 0.0))
        backButtonPath.close()
        backButtonPath.move(to: CGPoint(x: 11.98, y: 19.9))
        backButtonPath.addLine(to: CGPoint(x: 10.88, y: 21))
        backButtonPath.addLine(to: CGPoint(x: 0.54, y: 11.21))
        backButtonPath.addLine(to: CGPoint(x: 1.64, y: 10.11))
        backButtonPath.addLine(to: CGPoint(x: 11.98, y: 19.9))
        backButtonPath.close()
        backColor.setFill()
        backButtonPath.fill()
        
        backButtonImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return backButtonImage
    }

    static func forwardButtonIcon() -> UIImage {
        var forwardButtonImage: UIImage

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 12.0, height: 21.0), false, UIScreen.main.scale)

        let forwardColor = UIColor.black
        let forwardButtonPath = UIBezierPath()
        forwardButtonPath.move(to: CGPoint(x: 1.1, y: 0.0))
        forwardButtonPath.addLine(to: CGPoint(x: 0.0, y: 1.1))
        forwardButtonPath.addLine(to: CGPoint(x: 10.9, y: 11.75))
        forwardButtonPath.addLine(to: CGPoint(x: 12.0, y: 10.7))
        forwardButtonPath.addLine(to: CGPoint(x: 1.1, y: 0))
        forwardButtonPath.close()
        forwardButtonPath.move(to: CGPoint(x: 0.02, y: 19.9))
        forwardButtonPath.addLine(to: CGPoint(x: 1.12, y: 21.0))
        forwardButtonPath.addLine(to: CGPoint(x: 11.46, y: 11.21))
        forwardButtonPath.addLine(to: CGPoint(x: 10.36, y: 10.11))
        forwardButtonPath.addLine(to: CGPoint(x: 0.02, y: 19.9))
        forwardButtonPath.close()
        forwardColor.setFill()
        forwardButtonPath.fill()

        forwardButtonImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return forwardButtonImage
    }

    static func refreshButtonIcon() -> UIImage {
        var refreshButtonImage: UIImage

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 19.0, height: 22.0), false, UIScreen.main.scale)

        let refreshColor = UIColor.black
        let refreshButtonPath = UIBezierPath()
        refreshButtonPath.move(to: CGPoint(x: 18.98, y: 12.0))
        refreshButtonPath.addCurve(to: CGPoint(x: 19, y: 12.8), controlPoint1: CGPoint(x: 18.99, y: 12.11), controlPoint2: CGPoint(x: 19, y: 12.69))
        refreshButtonPath.addCurve(to: CGPoint(x: 9.5, y: 22), controlPoint1: CGPoint(x: 19, y: 17.88), controlPoint2: CGPoint(x: 14.75, y: 22))
        refreshButtonPath.addCurve(to: CGPoint(x: 0, y: 12.8), controlPoint1: CGPoint(x: 4.25, y: 22), controlPoint2: CGPoint(x: 0, y: 17.88))
        refreshButtonPath.addCurve(to: CGPoint(x: 10, y: 3.5), controlPoint1: CGPoint(x: 0, y: 7.72), controlPoint2: CGPoint(x: 4.75, y: 3.5))
        refreshButtonPath.addCurve(to: CGPoint(x: 10, y: 5), controlPoint1: CGPoint(x: 10.02, y: 3.5), controlPoint2: CGPoint(x: 10.02, y: 5))
        refreshButtonPath.addCurve(to: CGPoint(x: 1.69, y: 12.8), controlPoint1: CGPoint(x: 5.69, y: 5), controlPoint2: CGPoint(x: 1.69, y: 8.63))
        refreshButtonPath.addCurve(to: CGPoint(x: 9.5, y: 20.36), controlPoint1: CGPoint(x: 1.69, y: 16.98), controlPoint2: CGPoint(x: 5.19, y: 20.36))
        refreshButtonPath.addCurve(to: CGPoint(x: 17.31, y: 12), controlPoint1: CGPoint(x: 13.81, y: 20.36), controlPoint2: CGPoint(x: 17.31, y: 16.18))
        refreshButtonPath.addCurve(to: CGPoint(x: 17.28, y: 12), controlPoint1: CGPoint(x: 17.31, y: 11.89), controlPoint2: CGPoint(x: 17.28, y: 12.11))

        refreshButtonPath.addLine(to: CGPoint(x: 18.98, y: 12))
        refreshButtonPath.close()
        refreshButtonPath.move(to: CGPoint(x: 10.0,y: 0.0))
        refreshButtonPath.addLine(to: CGPoint(x: 17.35, y: 4.62))
        refreshButtonPath.addLine(to: CGPoint(x: 10, y: 9.13))
        refreshButtonPath.addLine(to: CGPoint(x: 10, y: 0))
        refreshButtonPath.close()
        refreshColor.setFill()
        refreshButtonPath.fill()

        refreshButtonImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return refreshButtonImage
    }

    static func stopButtonIcon() -> UIImage {
        var stopButtonImage: UIImage

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 19.0, height: 19.0), false, UIScreen.main.scale)

        let stopColor = UIColor.black
        let stopButtonPath = UIBezierPath()
        stopButtonPath.move(to: CGPoint(x: 19, y: 17.82))
        stopButtonPath.addLine(to: CGPoint(x: 17.82, y: 19))
        stopButtonPath.addLine(to: CGPoint(x: 9.5, y: 10.68))
        stopButtonPath.addLine(to: CGPoint(x: 1.18, y: 19))
        stopButtonPath.addLine(to: CGPoint(x: 0, y: 17.82))
        stopButtonPath.addLine(to: CGPoint(x: 8.32, y: 9.5))
        stopButtonPath.addLine(to: CGPoint(x: 0, y: 1.18))
        stopButtonPath.addLine(to: CGPoint(x: 1.18, y: 0))
        stopButtonPath.addLine(to: CGPoint(x: 9.5, y: 8.32))
        stopButtonPath.addLine(to: CGPoint(x: 17.82, y: 0))
        stopButtonPath.addLine(to: CGPoint(x: 19, y: 1.18))
        stopButtonPath.addLine(to: CGPoint(x: 10.68, y: 9.5))
        stopButtonPath.addLine(to: CGPoint(x: 19, y: 17.82))

        stopButtonPath.close()
        stopColor.setFill()
        stopButtonPath.fill()
        stopButtonImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return stopButtonImage
    }

    static func actionButtonIcon() -> UIImage {
        var actionButtonImage: UIImage

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 19.0, height: 30.0), false, UIScreen.main.scale)

        let actionColor = UIColor.black
        let actionButtonPath = UIBezierPath()

        actionButtonPath.move(to: CGPoint(x: 1, y: 9))
        actionButtonPath.addLine(to: CGPoint(x: 1, y: 26.02))
        actionButtonPath.addLine(to: CGPoint(x: 18, y: 26.02))
        actionButtonPath.addLine(to: CGPoint(x: 18, y: 9))
        actionButtonPath.addLine(to: CGPoint(x: 12, y: 9))
        actionButtonPath.addLine(to: CGPoint(x: 12, y: 8))
        actionButtonPath.addLine(to: CGPoint(x: 19, y: 8))
        actionButtonPath.addLine(to: CGPoint(x: 19, y: 27))
        actionButtonPath.addLine(to: CGPoint(x: 0, y: 27))
        actionButtonPath.addLine(to: CGPoint(x: 0, y: 8))
        actionButtonPath.addLine(to: CGPoint(x: 7, y: 8))
        actionButtonPath.addLine(to: CGPoint(x: 7, y: 9))
        actionButtonPath.addLine(to: CGPoint(x: 1, y: 9))
        actionButtonPath.close()
        actionButtonPath.move(to: CGPoint(x: 9, y: 0.98))
        actionButtonPath.addLine(to: CGPoint(x: 10, y: 0.98))
        actionButtonPath.addLine(to: CGPoint(x: 10, y: 17))
        actionButtonPath.addLine(to: CGPoint(x: 9, y: 17))
        actionButtonPath.addLine(to: CGPoint(x: 9, y: 0.98))
        actionButtonPath.close()
        actionButtonPath.move(to: CGPoint(x: 13.99, y: 4.62))
        actionButtonPath.addLine(to: CGPoint(x: 13.58, y: 5.01))
        actionButtonPath.addCurve(to: CGPoint(x: 13.25, y: 5.02), controlPoint1: CGPoint(x: 13.49, y: 5.1), controlPoint2: CGPoint(x: 13.34, y: 5.11))
        actionButtonPath.addLine(to: CGPoint(x: 9.43, y: 1.27))
        actionButtonPath.addCurve(to: CGPoint(x: 9.44, y: 0.94), controlPoint1: CGPoint(x: 9.34, y: 1.18), controlPoint2: CGPoint(x: 9.35, y: 1.04))
        actionButtonPath.addLine(to: CGPoint(x: 9.85, y: 0.56))
        actionButtonPath.addCurve(to: CGPoint(x: 10.18, y: 0.55), controlPoint1: CGPoint(x: 9.94, y: 0.46), controlPoint2: CGPoint(x: 10.09, y: 0.46))
        actionButtonPath.addLine(to: CGPoint(x: 14, y: 4.29))
        actionButtonPath.addCurve(to: CGPoint(x: 13.99, y: 4.62), controlPoint1: CGPoint(x: 14.09, y: 4.38), controlPoint2: CGPoint(x: 14.08, y: 4.53))
        actionButtonPath.close()
        actionButtonPath.move(to: CGPoint(x: 5.64, y: 4.95))
        actionButtonPath.addLine(to: CGPoint(x: 5.27, y: 4.56))
        actionButtonPath.addCurve(to: CGPoint(x: 5.26, y: 4.23), controlPoint1: CGPoint(x: 5.18, y: 4.47), controlPoint2: CGPoint(x: 5.17, y: 4.32))
        actionButtonPath.addLine(to: CGPoint(x: 9.46, y: 0.07))
        actionButtonPath.addCurve(to: CGPoint(x: 9.79, y: 0.07), controlPoint1: CGPoint(x: 9.55, y: -0.02), controlPoint2: CGPoint(x: 9.69, y: -0.02))
        actionButtonPath.addLine(to: CGPoint(x: 10.16, y: 0.47))
        actionButtonPath.addCurve(to: CGPoint(x: 10.17, y: 0.8), controlPoint1: CGPoint(x: 10.25, y: 0.56), controlPoint2: CGPoint(x: 10.26, y: 0.71))
        actionButtonPath.addLine(to: CGPoint(x: 5.97, y: 4.96))
        actionButtonPath.addCurve(to: CGPoint(x: 5.64, y: 4.95), controlPoint1: CGPoint(x: 5.88, y: 5.05), controlPoint2: CGPoint(x: 5.74, y: 5.05))

        actionButtonPath.close()
        actionColor.setFill()
        actionButtonPath.fill()
        actionButtonImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return actionButtonImage
    }

}

