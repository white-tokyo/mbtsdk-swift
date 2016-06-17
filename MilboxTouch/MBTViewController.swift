//
//  MBTHelper.swift
//  MilboxTouch
//
//  Created by TakumiOhtani on 2016/06/02.
//  Copyright © 2016年 white. All rights reserved.
//

import Foundation
import UIKit


public class MBTViewController: UIViewController {
    
    /// ヘルパーのセットアップが完了しているか
    var setupState: MBTViewControllerState {
        if let setupState = state as? MBTSetupState {
            return setupState.isSettingUp ? .SettingUp : .NotReady
        }
        return .Ready
    }
    var setupStageCount = 5
    var setupAllowableSpan: CGFloat = 10
    
    // イベントを検知する誤差範囲パラメータ
    var tapDetectSpan: CGFloat = 1
    var tapDetectTimeSpan: NSTimeInterval = 0.3
    var doubleTapDetectSpan: CGFloat = 10
    var doubleTapDetectTimeSpan: NSTimeInterval = 0.3
    var swipeDetectSpan: CGFloat = 50
    
    private var currentSetupStageCount = 0
    private var setupStageAllowed = false
    
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
            ss.setupAllowableSpan = setupAllowableSpan
            ss.isSettingUp = true
            state = ss
        }
    }
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
            NSLog("began position:\(position)")
            state.touchBegan(position)
        }
    }
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
            state.touchMoved(position)
            if let detectState = state as? MBTDetectState {
                if let delta = detectState.checkScroll() {
                    onScroll(delta)
                }
            }
        }
    }
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
                NSLog("ended")
        if let touch = touches.first {
            let endPosition = touch.locationInView(self.view).y
            state.touchEnded(endPosition)
            
            if let setupState = state as? MBTSetupState {
                if setupState.setupCompleted {
                    NSLog("セットアップ完了")
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
    var stageLimit: Int = 5
    var currentStageCount: Int = 0
    var isSettingUp: Bool = false {
        didSet {
            if oldValue && !isSettingUp {//trueからfalseへの変更拒否
                isSettingUp = true
                return
            }
            if isSettingUp && !oldValue {
                NSLog("初期化開始")
                currentStageCount = 0
                stageAllowed = false
                stageStarted = false
            }
        }
    }
    var stageAllowed = false
    var setupAllowableSpan: CGFloat = 10
    var leftLimit: CGFloat = 0
    var rightLimit: CGFloat = 0
    var stageStarted = false
    var setupCompleted: Bool {
        return stageLimit <= currentStageCount
    }
    
    override func touchBegan(position: CGFloat){
        if !isSettingUp{
            isSettingUp = true
        }
        if stageStarted {
//            NSLog("開始と終了は交互に呼ぶ")
            return
        }
        stageStarted = true
        if currentStageCount == 0 {
            leftLimit = position
            rightLimit = position
            NSLog("ステージ0開始")
            return
        }
        stageAllowed = fabs(leftLimit - position) < setupAllowableSpan || fabs(rightLimit - position) < setupAllowableSpan
    }
    override func touchEnded(position: CGFloat){
        if !isSettingUp{
            isSettingUp = true
            return
        }
        if !stageStarted {
//            NSLog("開始と終了は交互に呼ぶ")
            return
        }
        stageStarted = false
        if currentStageCount == 0 {
            leftLimit = min(position, leftLimit)
            rightLimit = max(position, rightLimit)
            currentStageCount = 1
            NSLog("ステージ０完了")
            return
        }
        if !stageAllowed {//やり直し
            NSLog("ステージ\(currentStageCount)の開始ポイント誤差あり。やり直し")
            currentStageCount = 0
            return
        }
        if fabs(leftLimit - position) < setupAllowableSpan || fabs(rightLimit - position) < setupAllowableSpan {
            NSLog("ステージ\(currentStageCount)完了")
            currentStageCount += 1
        }else{
            NSLog("ステージ\(currentStageCount)の終了ポイント誤差あり。やり直し")
            currentStageCount = 0
        }
    }
    
}

class MBTDetectState: MBTState {
    var tapDetectSpan: CGFloat = 1
    var tapDetectTimeSpan: NSTimeInterval = 0.3
    var doubleTapDetectSpan: CGFloat = 10
    var doubleTapDetectTimeSpan: NSTimeInterval = 0.3
    
    var tapStartTime: NSDate = NSDate()
    var tapStartPosition: CGFloat = 0
    var lastMovePosition: CGFloat = 0
    var moveDelta: CGFloat = 0
    var lastTap:Tap?
    private var isDoubleTap: Bool = false
    private var isTap: Bool = false
    private var swipe: Swipe?
    
    override func touchBegan(position:CGFloat) {
//        NSLog("DetectStateタップ開始")
        tapStartTime = NSDate()
        tapStartPosition = position
        lastMovePosition = tapStartPosition
    }
    override func touchMoved(position: CGFloat){
//        NSLog("detectState移動")
        moveDelta = position - lastMovePosition
        lastMovePosition = position
    }
    override func touchEnded(position: CGFloat){
//        NSLog("detectState終了")
        let currentTime = NSDate()
        let tappingTime = currentTime.timeIntervalSinceDate(tapStartTime)
        if touchIsTap(position, tappingTimeSpan: tappingTime) {
            let currentTap = Tap(position: position, time: currentTime)
            if lastTap?.isDoubleTap(currentTap, detectSpan: doubleTapDetectSpan, detectTimeSpan: doubleTapDetectTimeSpan) ?? false {
                NSLog("ダブルタップ")
                isDoubleTap = true
                lastTap = nil
            }else {
                NSLog("タップ検知")
                isTap = true
                lastTap = currentTap
            }
        }else if toucheIsSwipe(position, tappingTimeSpan: tappingTime) {
            NSLog("スワイプ検知:")
            let sp = tapStartPosition
            let ep = position
            swipe = Swipe(startPosition: sp, endPosition: ep, timeSpan: tappingTime)
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
    
    private func touchIsTap(position: CGFloat, tappingTimeSpan: NSTimeInterval) -> Bool {
        let spanCheck = fabs(tapStartPosition - position) < tapDetectSpan
        let timeCheck = tappingTimeSpan < tapDetectTimeSpan
        return spanCheck && timeCheck
    }
    private func toucheIsSwipe(position: CGFloat, tappingTimeSpan: NSTimeInterval) -> Bool {
        let spanCheck = fabs(tapStartPosition - position) > tapDetectSpan
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
    var startPosition: CGFloat
    var endPosition: CGFloat
    var timeSpan: NSTimeInterval
    
    var speed:CGFloat {
        let dist = endPosition-startPosition
        let dt = CGFloat(timeSpan)
        return dist / dt
    }
    var direction: SwipeDirection {
        return startPosition > endPosition ? .Right : .Left
    }
    
    init(startPosition:CGFloat,endPosition:CGFloat,timeSpan:NSTimeInterval) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.timeSpan = timeSpan
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
