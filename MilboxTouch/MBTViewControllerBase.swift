//
//  MBTHelper.swift
//  MilboxTouch
//
//  Created by TakumiOhtani on 2016/06/02.
//  Copyright © 2016年 white. All rights reserved.
//

import Foundation
import UIKit


public class MBTViewControllerBase: UIViewController {
    
    /// ヘルパーのセットアップが完了しているか
    var setupState: MBTViewControllerState {
        if let setupState = state as? MBTSetupState {
            return setupState.isSettingUp ? .SettingUp : .NotReady
        }
        return .Ready
    }
    var setupStageCount = 50
    
    // イベントを検知する誤差範囲パラメータ
    var tapDetectSpan: CGFloat = 1
    var tapDetectTimeSpan: NSTimeInterval = 0.3
    var doubleTapDetectSpan: CGFloat = 10
    var doubleTapDetectTimeSpan: NSTimeInterval = 0.3
    var swipeDetectSpan: CGFloat = 50
    
//    private var currentSetupStageCount = 0
//    private var setupStageAllowed = false
    
    private var leftLimit: CGFloat = 0
    private var rightLimit: CGFloat = 0
    
    private var state: MBTState! = MBTSetupState()
    
    /**
     call before use MBTHelper
     */
    public func setup() {
        if state is MBTSetupState {
            let ss = MBTSetupState()
            ss.stageLimit = setupStageCount
            ss.isSettingUp = true
            state = ss
        }
    }
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
            NSLog("began rad:\(positionToAngle(position))")
            state.touchBegan(positionToAngle(position))
        }
    }
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
            NSLog("move rad:\(positionToAngle(position))")
            state.touchMoved(positionToAngle(position))
            if let detectState = state as? MBTDetectState {
                if let delta = detectState.checkScroll() {
                    onScroll(delta)
                }
            }
        }
    }
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        NSLog("ended")
        if let touch = touches.first {
            let endPosition = touch.locationInView(self.view).y
            state.touchEnded(positionToAngle(endPosition))
            
            if let setupState = state as? MBTSetupState {
                if setupState.setupCompleted {
                    NSLog("setup completed.")
                    leftLimit = setupState.leftLimit
                    rightLimit = setupState.rightLimit
                    onSetupCompleted()
                    state = MBTDetectState()
                }
            }else if let detectState = state as? MBTDetectState {
                if detectState.checkTap() {
                    onTap()
                }else if detectState.checkDoubleTap() {
                    onDoubleTap()
                }else if let swipe = detectState.checkSwipe() {
                    onSwipe(swipe.speed, direction: swipe.direction)
                }
            }
            
        }
    }
    
    
    func positionToAngle(position: CGFloat) -> CGFloat {
        if setupState != .Ready {
            return position
        }
        let dir = position - leftLimit
        let limitSpan = rightLimit - leftLimit
        let rate = dir / limitSpan
        let pi = CGFloat(M_PI)
        let correction: CGFloat = 140
        let angle = rate * 360 + correction
        return angle >= 360 ? angle - 360 : angle
        
    }
    
    
    public func onTap() {
        NSLog("ontap")
    }
    public func onDoubleTap() {
        NSLog("ondoubletap")
    }
    public func onSwipe(speed: CGFloat, direction: SwipeDirection) {
        NSLog("onswipe")
    }
    
    /**
     回転イベント
     - parameter rad: 時計回りの回転角
     */
    public func onScroll(rad: CGFloat) {//時計回りは左方向に検知される
        NSLog("onscroll")
    }
    
    public func onSetupCompleted() {
        NSLog("setup is completed!")
    }
}

class MBTState {
    func touchBegan(anglePosition: CGFloat) {
        NSLog("Override me !")
    }
    func touchMoved(anglePosition: CGFloat) {
        NSLog("Override me !")
    }
    func touchEnded(anglePosition: CGFloat) {
        NSLog("Override me !")
    }
}

class MBTSetupState: MBTState {
    var stageLimit: Int = 50
    var torrelance: CGFloat = 5
    var rightLimitHistory: [CGFloat] = []
    var leftLimitHistory: [CGFloat] = []
    var isSettingUp: Bool = false {
        didSet {
            if oldValue && !isSettingUp {//trueからfalseへの変更拒否
                isSettingUp = true
                return
            }
            if isSettingUp && !oldValue {
                NSLog("start initialize...")
                leftLimitHistory = []
                rightLimitHistory = []
            }
        }
    }
    var leftLimit: CGFloat = 0
    var rightLimit: CGFloat = 0
    var setupCompleted: Bool {
        if rightLimitHistory.count != stageLimit {
            return false
        }
        
        if let max = rightLimitHistory.maxElement(),let min = rightLimitHistory.minElement() {
//            NSLog("\nright-max: \(max)\nright-min: \(min)")
            if max - min > torrelance {
                NSLog("rightLimit is changing")
                return false
            }
        }
        if let max = leftLimitHistory.maxElement(),let min = leftLimitHistory.minElement() {
//            NSLog("\nleft-max: \(max)\nleft-min: \(min)")
            if max - min > torrelance {
                NSLog("leftLimit is changing")
                return false
            }
        }
        return true
    }
    private func appendHistory(right: CGFloat, left: CGFloat) {
//        NSLog("append")
        rightLimitHistory.append(right)
        leftLimitHistory.append(left)
        
        if rightLimitHistory.count > stageLimit {
//            NSLog("limit!!!!")
            rightLimitHistory.removeFirst()
        }
        if leftLimitHistory.count > stageLimit {
            leftLimitHistory.removeFirst()
        }
    }
    override func touchMoved(anglePosition: CGFloat) {
        leftLimit = leftLimit == 0 ? anglePosition : min(anglePosition, leftLimit)
        rightLimit = rightLimit == 0 ? anglePosition : max(anglePosition, rightLimit)
        appendHistory(rightLimit, left: leftLimit)
        NSLog("\nright: \(rightLimit)\nleft: \(leftLimit)")
    }
    override func touchBegan(anglePosition: CGFloat){
    }
    override func touchEnded(anglePosition: CGFloat){
    }
    
}

class MBTDetectState: MBTState {
    var tapDetectSpan: CGFloat = 1
    var tapDetectTimeSpan: NSTimeInterval = 0.3
    var doubleTapDetectSpan: CGFloat = 10
    var doubleTapDetectTimeSpan: NSTimeInterval = 0.3
    
    var tapStartTime: NSDate = NSDate()
    var tapStartAnglePosition: CGFloat = 0
    var lastMovePosition: CGFloat = 0
    var moveDelta: CGFloat = 0
    var lastTap:Tap?
    private var isDoubleTap: Bool = false
    private var isTap: Bool = false
    private var swipe: Swipe?
    
    override func touchBegan(anglePosition:CGFloat) {
//        NSLog("DetectStateタップ開始")
        tapStartTime = NSDate()
        tapStartAnglePosition = anglePosition
        lastMovePosition = tapStartAnglePosition
    }
    override func touchMoved(anglePosition: CGFloat){
//        NSLog("detectState移動")
        moveDelta = anglePosition - lastMovePosition
        lastMovePosition = anglePosition
    }
    override func touchEnded(anglePosition: CGFloat){
//        NSLog("detectState終了")
        let currentTime = NSDate()
        let tappingTime = currentTime.timeIntervalSinceDate(tapStartTime)
        if touchIsTap(anglePosition, tappingTimeSpan: tappingTime) {
            let currentTap = Tap(position: anglePosition, time: currentTime)
            if lastTap?.isDoubleTap(currentTap, detectSpan: doubleTapDetectSpan, detectTimeSpan: doubleTapDetectTimeSpan) ?? false {
                NSLog("ダブルタップ")
                isDoubleTap = true
                lastTap = nil
            }else {
                NSLog("タップ検知")
                isTap = true
                lastTap = currentTap
            }
        }else if toucheIsSwipe(anglePosition, tappingTimeSpan: tappingTime) {
            NSLog("スワイプ検知:")
            let sp = tapStartAnglePosition
            let ep = anglePosition
            swipe = Swipe(startAnglePosition: sp, endAnglePosition: ep, timeSpan: tappingTime)
        }
    }
    
    func checkScroll() -> CGFloat? {
        if fabs(moveDelta) > tapDetectSpan {
            return moveDelta
        }
        return nil
    }
    func checkTap() -> Bool {
        let tap = isTap
        isTap = false
        return tap
    }
    func checkDoubleTap() -> Bool {
        let doubleTap = isDoubleTap
        isDoubleTap = false
        return doubleTap
    }
    func checkSwipe() -> Swipe? {
        if let swipe = swipe {
            self.swipe = nil
            return swipe
        }
        return nil
    }
    
    private func touchIsTap(anglePosition: CGFloat, tappingTimeSpan: NSTimeInterval) -> Bool {
        let spanCheck = fabs(tapStartAnglePosition - anglePosition) < tapDetectSpan
        let timeCheck = tappingTimeSpan < tapDetectTimeSpan
        return spanCheck && timeCheck
    }
    private func toucheIsSwipe(anglePosition: CGFloat, tappingTimeSpan: NSTimeInterval) -> Bool {
        let spanCheck = fabs(tapStartAnglePosition - anglePosition) > tapDetectSpan
        let timeCheck = tappingTimeSpan < tapDetectTimeSpan
        return spanCheck && timeCheck
    }
}

class Tap {
    var position: CGFloat
    var time: NSDate
    
    init(position:CGFloat,time: NSDate = NSDate()){
        self.position = position
        self.time = time
    }
    
    func isDoubleTap(secondTap: Tap,detectSpan: CGFloat, detectTimeSpan: NSTimeInterval) -> Bool{
        return fabs(position-secondTap.position) < detectSpan && secondTap.time.timeIntervalSinceDate(time) < detectTimeSpan
    }
}
class Swipe {
    var startAnglePosition: CGFloat
    var endAnglePosition: CGFloat
    var timeSpan: NSTimeInterval
    
    var speed:CGFloat {
        let dist = endAnglePosition-startAnglePosition
        let dt = CGFloat(timeSpan)
        return dist / dt
    }
    var direction: SwipeDirection {
        let s = checkAngleBlock(startAnglePosition)
        let e = checkAngleBlock(endAnglePosition)
        switch s {
        case .UpperLeft:
            if e == .UpperRight {
                return .Right
            }else if e == .LowerLeft {
                return .Down
            }
        case .UpperRight:
            if e == .UpperLeft {
                return .Left
            }else if e == .LowerRight {
                return .Down
            }
        case .LowerLeft:
            if e == .UpperLeft {
                return .Up
            }else if e == .LowerRight {
                return .Right
            }
        case .LowerRight: 
            if e == .UpperRight {
                return .Up
            }else if e == .LowerLeft {
                return .Left
            }
        }
        return startAnglePosition > endAnglePosition ? .Right : .Left
    }
    
    init(startAnglePosition:CGFloat,endAnglePosition:CGFloat,timeSpan:NSTimeInterval) {
        self.startAnglePosition = startAnglePosition
        self.endAnglePosition = endAnglePosition
        self.timeSpan = timeSpan
        NSLog("swipe:::\ns: \(startAnglePosition)\ns: \(endAnglePosition)")
    }
    
    func checkAngleBlock(angle: CGFloat) -> AngleBlock {
        if 0 <= angle && angle < 90 {
            return .UpperRight
        }else if 90 <= angle && angle < 180 {
            return .UpperLeft
        }else if 180 <= angle && angle < 270 {
            return .LowerLeft
        }
        return .LowerRight
    }
    
    enum AngleBlock{
        case UpperLeft
        case UpperRight
        case LowerLeft
        case LowerRight
    }
    
}


@objc public enum SwipeDirection: Int {
    case Up
    case Down
    case Right
    case Left
}
public enum MBTViewControllerState: Int {
    case NotReady
    case SettingUp
    case Ready
}

extension CGPoint {
    func dist(other: CGPoint) -> CGFloat {
        let dx = self.x - other.x
        let dy = self.y - other.y
        return sqrt(dx*dx+dy*dy)
    }
    
}
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
