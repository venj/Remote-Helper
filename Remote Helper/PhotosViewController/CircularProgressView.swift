//
//  CircularProgressView.swift
//  Demo
//

import UIKit

final class CircularProgressView: UIView {
    var progress: CGFloat = 0 {
        didSet {
            progressLayer.strokeEnd = min(max(progress, 0), 1)
        }
    }
    
    private let trackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        layer.lineWidth = 3
        return layer
    }()
    
    private let progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.systemBlue.cgColor
        layer.lineCap = .round
        layer.lineWidth = 3
        layer.strokeEnd = 0
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.black.withAlphaComponent(0.18)
        layer.cornerRadius = 14
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.black.withAlphaComponent(0.18)
        layer.cornerRadius = 14
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 4
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(
            arcCenter: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
}
