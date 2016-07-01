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
    
    public var setupState: MBTViewControllerState {
        if let setupState = state as? MBTSetupState {
            return setupState.isSettingUp ? .SettingUp : .NotReady
        }
        return .Ready
    }
    
    //MARK: setupStage parameters
    
    public var setupStageCount: Int = 50 {
        didSet{
            if let state = state as? MBTSetupState {
                state.stageLimit = setupStageCount
            }
        }
    }
    public var setupTorrelance: CGFloat = 5 {
        didSet{
            if let state = state as? MBTSetupState {
                state.torrelance = setupTorrelance
            }
        }
    }
    
    //MARK: detectStage parameters
    
    public var tapDetectTorrelance: CGFloat = 25{
        didSet{
            if let state = state as? MBTDetectState {
                state.tapDetectTorrelence = tapDetectTorrelance
            }
        }
    }
    public var tapDetectDuration: NSTimeInterval = 0.3{
        didSet{
            if let state = state as? MBTDetectState {
                state.tapDetectDuration = tapDetectDuration
            }
        }
    }
    public var doubleTapDetectTorrelance: CGFloat = 10{
        didSet{
            if let state = state as? MBTDetectState {
                state.doubleTapDetectTorrelence = doubleTapDetectTorrelance
            }
        }
    }
    public var doubleTapDetectDuration: NSTimeInterval = 0.3{
        didSet{
            if let state = state as? MBTDetectState {
                state.doubleTapDetectDuration = doubleTapDetectDuration
            }
        }
    }
    
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
            ss.torrelance = setupTorrelance
            state = ss
        }
    }
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
//            NSLog("began pos:\(position)")
            state.touchBegan(position)
        }
    }
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
//            NSLog("move pos:\(position)")
            state.touchMoved(position)
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
            state.touchEnded(endPosition)
            
            if let setupState = state as? MBTSetupState {
                if setupState.setupCompleted {
                    NSLog("setup completed.")
                    leftLimit = setupState.leftLimit
                    rightLimit = setupState.rightLimit
                    onSetupCompleted()
                    
                    //change state to DetectingState
                    let detectState = MBTDetectState()
                    detectState.tapDetectTorrelence = tapDetectTorrelance
                    detectState.tapDetectDuration = tapDetectDuration
                    detectState.doubleTapDetectTorrelence = doubleTapDetectTorrelance
                    detectState.doubleTapDetectDuration = doubleTapDetectDuration
                    detectState.leftLimit = leftLimit
                    detectState.rightLimit = rightLimit
                    state = detectState
                }
            }else if let detectState = state as? MBTDetectState {
                if detectState.checkTap() {
                    onTap()
                }else if detectState.checkDoubleTap() {
                    onDoubleTap()
                }else if let swipe = detectState.checkSwipe() {
                    onSwipe(swipe.speed, direction: swipe.direction)
                }
                
                if detectState.scrolled {
                    detectState.scrolled = false
                    onScrollFinish()
                }
            }
            
        }
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
     rotation event
     - parameter rad: anticlockwise radian
     */
    public func onScroll(rad: CGFloat) {//時計回りは左方向に検知される
        NSLog("onscroll")
    }
    public func onScrollFinish(){
        NSLog("scroll finish")
    }
    
    public func onSetupCompleted() {
        NSLog("setup is completed!")
    }
}

class MBTState {
    func touchBegan(position: CGFloat) {
        NSLog("Override me !")
    }
    func touchMoved(position: CGFloat) {
        NSLog("Override me !")
    }
    func touchEnded(position: CGFloat) {
        NSLog("Override me !")
    }
}

class MBTSetupState: MBTState {
    var stageLimit: Int = 50
    var torrelance: CGFloat = 5
    var rightLimitHistory: [CGFloat] = []
    var leftLimitHistory: [CGFloat] = []
    var isSettingUp: Bool {
        return rightLimitHistory.count == 0 && leftLimitHistory.count == 0
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
    override func touchMoved(position: CGFloat) {
        leftLimit = leftLimit == 0 ? position : min(position, leftLimit)
        rightLimit = rightLimit == 0 ? position : max(position, rightLimit)
        appendHistory(rightLimit, left: leftLimit)
        NSLog("\nright: \(rightLimit)\nleft: \(leftLimit)")
    }
    override func touchBegan(position: CGFloat){
    }
    override func touchEnded(position: CGFloat){
    }
    
}

private class MBTDetectState: MBTState {
    var tapDetectTorrelence: CGFloat = 10//radian
    var tapDetectDuration: NSTimeInterval = 0.3//sec
    var doubleTapDetectTorrelence: CGFloat = 10//radian
    var doubleTapDetectDuration: NSTimeInterval = 0.3
    var leftLimit:CGFloat = 0
    var rightLimit:CGFloat = 0
    
    var tapStartTime: NSDate = NSDate()
    var tapStartAnglePosition: CGFloat = 0
    var lastMovePosition: CGFloat = 0
    var moveDelta: CGFloat = 0
    var lastTap:Tap?
    private var isDoubleTap: Bool = false
    private var isTap: Bool = false
    private var swipe: Swipe?
    private var scrolled: Bool = false
    
    override func touchBegan(position:CGFloat) {
        let anglePosition = positionToAngle(position)
        
        tapStartTime = NSDate()
        tapStartAnglePosition = anglePosition
        lastMovePosition = tapStartAnglePosition
//        NSLog("beganRad \(tapStartAnglePosition)")
    }
    override func touchMoved(position: CGFloat){
        let anglePosition = positionToAngle(position)
        moveDelta = anglePosition - lastMovePosition
        lastMovePosition = anglePosition
        if !scrolled && checkScroll() != nil {
            scrolled = true
        }
//        NSLog("detect: move -> delta :: \(moveDelta)")
    }
    override func touchEnded(position: CGFloat){
        let anglePosition = positionToAngle(position)
        let currentTime = NSDate()
        let tappingTime = currentTime.timeIntervalSinceDate(tapStartTime)
//        NSLog("endrad:: \(anglePosition)\ntime :: \(tappingTime)\ndelta\(anglePosition-tapStartAnglePosition)")
        
        if touchIsTap(anglePosition, tappingTimeSpan: tappingTime) {
            let currentTap = Tap(position: anglePosition, time: currentTime)
            if lastTap?.isDoubleTap(currentTap, detectSpan: doubleTapDetectTorrelence, detectTimeSpan: doubleTapDetectDuration) ?? false {
                isDoubleTap = true
                lastTap = nil
            }else {
                isTap = true
                lastTap = currentTap
            }
        }else if toucheIsSwipe(anglePosition, tappingTimeSpan: tappingTime) {
            let sp = tapStartAnglePosition
            let ep = anglePosition
            swipe = Swipe(startAnglePosition: sp, endAnglePosition: ep, timeSpan: tappingTime)
        }
    }
    
    func checkScroll() -> CGFloat? {
        let moveDist = fabs(moveDelta)
        if moveDist > 0.3 && moveDist < 10{
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
        let spanCheck = fabs(tapStartAnglePosition - anglePosition) < tapDetectTorrelence
        let timeCheck = tappingTimeSpan < tapDetectDuration
        return spanCheck && timeCheck
    }
    private func toucheIsSwipe(anglePosition: CGFloat, tappingTimeSpan: NSTimeInterval) -> Bool {
        let angleCheck = fabs(tapStartAnglePosition - anglePosition) > tapDetectTorrelence
        let timeCheck = tappingTimeSpan < tapDetectDuration
        return angleCheck && timeCheck
    }
    
    private func positionToAngle(var position: CGFloat) -> CGFloat {
        if position < leftLimit {
            position = leftLimit
        }else if rightLimit < position {
            position = rightLimit
        }
        let dir = position - leftLimit
        let limitSpan = rightLimit - leftLimit
        let rate = dir / limitSpan
        let pi = CGFloat(M_PI)
        let correction: CGFloat = 140
        let angle = rate * 360 + correction
        return angle >= 360 ? angle - 360 : angle
        
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
//        NSLog("swipe:::\ns: \(startAnglePosition)\ns: \(endAnglePosition)")
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
