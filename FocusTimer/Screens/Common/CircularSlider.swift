//
//  CircularSlider.swift
//  FocusTimer
//
//  Created by jh on 7/31/24.
//

import UIKit


enum SetColors: Int {
    case red = 0
    case dark = 1
}
class CircularSlider: UIControl {
    private var trackLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()
    private var thumbLayer = CAShapeLayer()
    private var fillLayer = CAShapeLayer()
    private var ticksLayer = CAShapeLayer()
    private var labelsLayer = CAShapeLayer()
    
    private var radius: CGFloat {
        return min(bounds.width, bounds.height) / 2 - trackLayer.lineWidth / 2
    }
    private var thumbRadius: CGFloat = 10
    private var angle: CGFloat = -.pi / 2
    private var value: CGFloat = 0 // 0.0 to 1.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        
        
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 10
        layer.addSublayer(trackLayer)
        
        fillLayer.fillColor = UIColor(red: 255 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1).cgColor
        fillLayer.shadowColor = UIColor.black.cgColor
        fillLayer.shadowOpacity = 0.2
        fillLayer.shadowOffset = CGSize(width: 3, height: 3)
        fillLayer.shadowRadius = 3
        layer.addSublayer(fillLayer)
        
        
        ticksLayer.strokeColor = UIColor.black.cgColor
        ticksLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(ticksLayer)
        
        labelsLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(labelsLayer)
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor(red: 255 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1).cgColor
        progressLayer.lineWidth = 9
        progressLayer.lineCap = .butt
        layer.addSublayer(progressLayer)
        
        thumbLayer.fillColor = UIColor.white.cgColor
        thumbLayer.strokeColor = UIColor(red: 255 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1).cgColor
        thumbLayer.lineWidth = 3
        layer.addSublayer(thumbLayer)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTrackPath()
        updateThumbPosition()
        updateFillLayer()
        drawTicksAndLabels()
    }
    
    private func updateTrackPath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true)
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
    
    private func updateThumbPosition() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let thumbCenter = CGPoint(x: center.x + radius * cos(angle),
                                  y: center.y + radius * sin(angle))
        thumbLayer.path = UIBezierPath(ovalIn: CGRect(x: thumbCenter.x - thumbRadius, y: thumbCenter.y - thumbRadius, width: thumbRadius * 2, height: thumbRadius * 2)).cgPath
        
        progressLayer.strokeEnd = value
    }
    
    private func updateFillLayer() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle: CGFloat = -.pi / 2
        let endAngle = angle
        
        let fillPath = UIBezierPath()
        fillPath.move(to: center)
        fillPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        fillPath.close()
        
        fillLayer.path = fillPath.cgPath
    }
    
    private func drawTicksAndLabels() {
        ticksLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        labelsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let thickTickPath = UIBezierPath()
        let thinTickPath = UIBezierPath()
        
        let labelFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.black
        ]

        for i in 0..<60 {
            let angle = (CGFloat(i) * .pi / 30) - .pi / 2
            let tickLength: CGFloat = (i % 5 == 0) ? 26 : 14
            let tickStart = CGPoint(x: center.x + (radius - tickLength) * cos(angle),
                                    y: center.y + (radius - tickLength) * sin(angle))
            let tickEnd = CGPoint(x: center.x + radius * cos(angle),
                                  y: center.y + radius * sin(angle))
            
            if i % 5 == 0 {
                thickTickPath.move(to: tickStart)
                thickTickPath.addLine(to: tickEnd)
                
                let label = "\(i)"
                let labelSize = label.size(withAttributes: attributes)
                let labelAngle = (CGFloat(i) * .pi / 30) - .pi / 2
                let labelRadius = radius + 20
                let labelCenter = CGPoint(x: center.x + labelRadius * cos(labelAngle) - labelSize.width / 2,
                                          y: center.y + labelRadius * sin(labelAngle) - labelSize.height / 2)
                let labelRect = CGRect(origin: labelCenter, size: labelSize)
                let labelLayer = CATextLayer()
                labelLayer.string = label
                labelLayer.fontSize = labelFont.pointSize
                labelLayer.foregroundColor = UIColor.black.cgColor
                labelLayer.alignmentMode = .center
                labelLayer.contentsScale = UIScreen.main.scale
                labelLayer.font = UIFont.systemFont(ofSize: 16, weight: .light)
                labelLayer.frame = labelRect
                labelsLayer.addSublayer(labelLayer)
            } else {
                thinTickPath.move(to: tickStart)
                thinTickPath.addLine(to: tickEnd)
            }
        }
        
        let thickTickLayer = CAShapeLayer()
        thickTickLayer.path = thickTickPath.cgPath
        thickTickLayer.strokeColor = UIColor.black.cgColor
        thickTickLayer.lineWidth = 2
        thickTickLayer.fillColor = UIColor.clear.cgColor
        
        let thinTickLayer = CAShapeLayer()
        thinTickLayer.path = thinTickPath.cgPath
        thinTickLayer.strokeColor = UIColor.black.cgColor
        thinTickLayer.lineWidth = 1
        thinTickLayer.fillColor = UIColor.clear.cgColor
        
        ticksLayer.addSublayer(thickTickLayer)
        ticksLayer.addSublayer(thinTickLayer)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let newAngle = atan2(dy, dx)
        
        var newValue = (newAngle + .pi / 2) / (2 * .pi)
        if newValue < 0 {
            newValue += 1
        }
        
        value = min(max(newValue, 0), 1)
        angle = value * 2 * .pi - .pi / 2
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateThumbPosition()
        updateFillLayer()
        CATransaction.commit()
        
        sendActions(for: .valueChanged)

        switch gesture.state {
        case .ended, .cancelled, .failed:
            sendActions(for: .editingDidEnd)
        default:
            break
        }
    }
    
    func setValue(_ newValue: CGFloat, animated: Bool = false) {
        value = min(max(newValue, 0), 1)
        angle = value * 2 * .pi - .pi / 2
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateThumbPosition()
        updateFillLayer()
        CATransaction.commit()
    }
    
    func getValue() -> CGFloat {
        return value
    }
    func setColor(color: SetColors) {
        if color == .red {
            fillLayer.fillColor = UIColor(red: 255 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1).cgColor
            progressLayer.strokeColor = UIColor(red: 255 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1).cgColor
            thumbLayer.strokeColor = UIColor(red: 255 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1).cgColor
        } else {
            progressLayer.strokeColor = UIColor.black.cgColor
            thumbLayer.strokeColor = UIColor.black.cgColor
            fillLayer.fillColor = UIColor(red: 206 / 255, green: 206 / 255, blue: 206 / 255, alpha: 1).cgColor
        }
    }
}
