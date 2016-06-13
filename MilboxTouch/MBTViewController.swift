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
    private var tapStartTime: NSDate = NSDate(timeIntervalSince1970: 0)
    private var tapStartPosition: CGFloat = 0
    private var lastTapTime: NSDate = NSDate(timeIntervalSince1970: 0)
    private var lastTapPosition: CGFloat = 0
    private var lastMovePosition: CGFloat = 0
    
    private var state: MBTState!
    
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
            state.touchBegan(position)
        }
    }
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.locationInView(self.view).y
            state.touchMoved(position)
            if let detectState = state as? MBTDetectState {
                let delta = position - lastMovePosition
                if fabs(delta) > tapDetectSpan {
                    onScroll(delta)
                }
                lastMovePosition = position
            }
        }
    }
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //        NSLog("ended")
        if let touch = touches.first {
            let tappingTime = NSDate().timeIntervalSinceDate(tapStartTime)
            let endPosition = touch.locationInView(self.view).y
            state.touchEnded(endPosition)
            
            if let setupState = state as? MBTSetupState {
                if setupState.setupCompleted {
                    NSLog("セットアップ完了")
                    onSetupCompleted()
                    state = MBTDetectState()
                }
            }
            
            if setupState == .SettingUp {//初期化処理ステージ
            }else if setupState == .Ready {//通常
                //detect tap,doubleTap
                if fabs(tapStartPosition - endPosition) < tapDetectSpan {
                    if tappingTime < tapDetectTimeSpan {
                        tapDetected(endPosition)
                    }
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
    
    func tapDetected(position: CGFloat) {
        let currentTime = NSDate()
        let tapIntervalTime = currentTime.timeIntervalSinceDate(lastTapTime)
        if tapIntervalTime < doubleTapDetectTimeSpan {
            if fabs(position - lastTapPosition) < doubleTapDetectSpan {
                onDoubleTap()
                lastTapTime = NSDate(timeIntervalSince1970: 0)
                return
            }
        }
        onTap()
        lastTapPosition = position
        lastTapTime = currentTime
    }
}


/*
 public delegate void Trigger();
	public delegate void TouchPad(float x, float y);
	public delegate void Gesture(string name);
	public delegate void Clockwise(bool flg, float avr);
 
	//タップの許容時間
	public const float tapDetectTime = 1.0f;
 
	//タップの許容移動距離
	public const float tapDetectLength = 15.0f;
 
	//ダブルタップの許容時間
	public float doubleTapDetectTime = 0.3f;
 
	public float minSwipeDistX;
	public float minSwipeDistY;
 
	private Vector2 tapBeganPos = Vector2.zero;
	private float touchTime = 0.0f;
	private float lastTapTime = 0.0f;
	private int tapCountPerTime = 0;
	private int lastTime = 0;
	private bool charged = false;
 
	//回転は数フレーム分のアベレージを取る
	private	const int	CLOCK_AVR_NUM			= 5;
	private	const float	CLOCK_AVR_THRESHOLD 	= 1.0f;		//TODO 端末によって解像度が違うので何かしらの方法で最大近辺最小近辺を取得して適宜な値に動的に調整が好ましい
	public	float		clockAvr;
 
 
 // charge - 一定フレーム以内に複数の反応があった場合
 // doubleTap - 一定秒数以内に複数回のタップがあった場合
	}
 
	void Update () {
 
 MBTTouch.Update();
 CarcAvarage();
 
 if (MBTTouch.touchCount == 0) {
 return;
 }
 
 //check charge
 if(!charged){
 if (lastTime == (int)Time.time) {
 tapCountPerTime += 1;
 
 if (tapCountPerTime > chargeDetectTapCount) {
 charged = true;
 OnCharge ();
 }
 } else {
 tapCountPerTime = 0;
 lastTime = (int)Time.time;
 }
 }
 
 switch (MBTTouch.phase) {
 case TouchPhase.Began:
 tapBeganPos = MBTTouch.position;
 break;
 case TouchPhase.Moved:
 case TouchPhase.Stationary:
 touchTime += Time.deltaTime;
 
 Vector3 vp = MBTTouch.deltaPosition;
 if (vp.sqrMagnitude > tapDetectLength*tapDetectLength) {
 if (vp.x*vp.x > vp.y*vp.y){
 OnScroll(MBTTouch.position.x, 0);
 } else {
 OnScroll(0, MBTTouch.position.y);
 }
 }
 
 if( CLOCK_AVR_THRESHOLD < clockAvr )
 {
 OnClockwise(false, clockAvr);		//TODO ここで機種依存の値、clockAvrを渡しているが機種依存しない形に修正したい
 }
 else if( clockAvr < -CLOCK_AVR_THRESHOLD )
 {
 OnClockwise(true, clockAvr);		//TODO 上記に同じ
 }
 
 break;
 
 case TouchPhase.Ended:
 case TouchPhase.Canceled:
 
 var endPos = MBTTouch.position;
 
 //check tap and double tap.
 if (touchTime < tapDetectTime) {
 if ((endPos - tapBeganPos).sqrMagnitude < tapDetectLength*tapDetectLength) {
 if ((Time.time - lastTapTime) < doubleTapDetectTime) {
 OnDoubleTap ();
 lastTapTime = 0f;
 } else {
 OnTap ();
 lastTapTime = Time.time;
 }
 touchTime = 0.0f;
 return;
 }
 }
 
 if (Mathf.Abs (endPos.x - tapBeganPos.x) > minSwipeDistX) {
 
 if (endPos.x > tapBeganPos.x) {
 OnSwipe ("RIGHTSwipe");
 } else {
 OnSwipe ("LEFTSwipe");
 }
 }else if (Mathf.Abs (endPos.y - tapBeganPos.y) > minSwipeDistY) {
 
 if (endPos.y > tapBeganPos.y) {
 OnSwipe ("UPSwipe");
 } else{
 OnSwipe ("DownSwipe");
 }
 }
 touchTime = 0.0f;
 break;
 }
 
	}
 
	private void CarcAvarage()
	{
 float dx = 0f;
 if( 0 < MBTTouch.touchCount )
 {
 dx = MBTTouch.deltaPosition.x;
 }
 
 clockAvr = (clockAvr*(CLOCK_AVR_NUM-1) + dx) / CLOCK_AVR_NUM;
 
	}
 
 
 */

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
            NSLog("開始と終了は交互に呼んでね")
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
            NSLog("開始と終了は交互に呼んでね")
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
    var tapDetectSpan: CGFloat = 10
    var tapDetectTimeSpan: NSTimeInterval = 0.3
    var doubleTapDetectSpan: CGFloat = 10
    var doubleTapDetectTimeSpan: NSTimeInterval = 0.3
    
    var tapStartTime: NSDate = NSDate()
    var tapStartPosition: CGFloat = 0
    var lastMovePosition: CGFloat = 0
    var moveDelta: CGFloat = 0
    var lastTap:Tap?
    
    override func touchBegan(position:CGFloat) {
        tapStartTime = NSDate()
        tapStartPosition = position
        lastMovePosition = tapStartPosition
    }
    override func touchMoved(position: CGFloat){
        moveDelta = position - lastMovePosition
        lastMovePosition = position
    }
    override func touchEnded(position: CGFloat){
        let currentTime = NSDate()
        let tappingTime = currentTime.timeIntervalSinceDate(tapStartTime)
        if fabs(tapStartPosition - position) < tapDetectSpan {
            if tappingTime < tapDetectTimeSpan {//tap!
                let currentTap = Tap(position: position, time: currentTime)
                if lastTap!.isDoubleTap(currentTap, detectSpan: doubleTapDetectSpan, detectTimeSpan: doubleTapDetectTimeSpan) {
                    //onDoubleTap()
                    lastTap = Tap(position: 0, time: NSDate(timeIntervalSince1970: 0))
                    return
                }else {
                    //onTap()
                    lastTap = currentTap
                }
            }
        }
    }
    
    func checkScroll() -> CGFloat? {
        if fabs(moveDelta) > tapDetectSpan {
            return moveDelta
        }
        return nil
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
