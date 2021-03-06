//
//  ViewController.swift
//  simple360player
//
//  Created by Arthur Swiniarski on 04/01/16.
//  Copyright © 2016 Arthur Swiniarski. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation
import Foundation
import Darwin
import CoreGraphics
import MilboxTouch

// ViewController
class ViewController: MBTViewControllerBase, SCNSceneRendererDelegate {
    
    @IBOutlet weak var leftSceneView                : SCNView!
    @IBOutlet weak var rightSceneView               : SCNView!
    
    @IBOutlet weak var heightSceneConstraint        : NSLayoutConstraint!
    @IBOutlet weak var widthSceneConstraint         : NSLayoutConstraint!
    
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    
    var scenes                                      : [SCNScene]!
    
    var videosNode                                  : [SCNNode]!
    var videosSpriteKitNode                         : [SKVideoNode]!
    
    var camerasNode                                 : [SCNNode]!
    var camerasRollNode                             : [SCNNode]!
    var camerasPitchNode                            : [SCNNode]!
    var camerasYawNode                              : [SCNNode]!
    
    var motionManager                               : CMMotionManager?
    
    var player                                      : AVPlayer!
    
    var currentAngleX                               : Float!
    var currentAngleY                               : Float!
    
    var playingVideo                                : Bool = false
    
    #if arch(arm64)
    var PROCESSOR_64BITS                            : Bool = true
    #else
    var PROCESSOR_64BITS                            : Bool = false
    #endif
    
    //MARK: View Did Load
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        leftSceneView.delegate                      = self
        rightSceneView.delegate                     = self
        
        let leftCamera                              = SCNCamera()
        let rightCamera                             = SCNCamera()
        leftCamera.zFar                             = 50.0
        rightCamera.zFar                            = 50.0
        
        let leftCameraNode                          = SCNNode()
        leftCameraNode.camera                       = leftCamera
        
        let rightCameraNode                         = SCNNode()
        rightCameraNode.camera                      = rightCamera
        
        let scene1                                  = SCNScene()
        
        let cameraNodeLeft                          = SCNNode()
        let cameraRollNodeLeft                      = SCNNode()
        let cameraPitchNodeLeft                     = SCNNode()
        let cameraYawNodeLeft                       = SCNNode()
        
        cameraNodeLeft.addChildNode(leftCameraNode)
        cameraNodeLeft.addChildNode(rightCameraNode)
        cameraRollNodeLeft.addChildNode(cameraNodeLeft)
        cameraPitchNodeLeft.addChildNode(cameraRollNodeLeft)
        cameraYawNodeLeft.addChildNode(cameraPitchNodeLeft)
        
        let dummyAction = SCNAction.scaleBy(1.0, duration: 1.0)
        let repeatAction = SCNAction.repeatActionForever(dummyAction)
        cameraNodeLeft.runAction(repeatAction)//renderer is not called ??
        
        leftSceneView.scene                         = scene1
        
        let scene2                              = SCNScene()
        let cameraNodeRight                     = SCNNode()
        let cameraRollNodeRight                 = SCNNode()
        let cameraPitchNodeRight                = SCNNode()
        let cameraYawNodeRight                  = SCNNode()
        
        scenes                                  = [scene1, scene2]
        camerasNode                             = [cameraNodeLeft, cameraNodeRight]
        camerasRollNode                         = [cameraRollNodeLeft, cameraRollNodeRight]
        camerasPitchNode                        = [cameraPitchNodeLeft, cameraPitchNodeRight]
        camerasYawNode                          = [cameraYawNodeLeft, cameraYawNodeRight]
        
        rightSceneView?.scene                   = scene2
        leftCamera.xFov                         = 80
        rightCamera.xFov                        = 80
        leftCamera.yFov                         = 80
        rightCamera.yFov                        = 80
        
        cameraNodeRight.addChildNode(rightCameraNode)
        cameraRollNodeRight.addChildNode(cameraNodeRight)
        cameraPitchNodeRight.addChildNode(cameraRollNodeRight)
        cameraYawNodeRight.addChildNode(cameraPitchNodeRight)
        
        let distance:Float = 0.5
        leftCameraNode.position                     = SCNVector3(x: 0 - distance, y: 0, z: 0)
        rightCameraNode.position                    = SCNVector3(x: 0 + distance, y: 0, z: 0)
        
        let camerasNodeAngles                       = getCamerasNodeAngle()
        
        for cameraNode in camerasNode {
            cameraNode.position                     = SCNVector3(x: 0, y:0, z:0)
            cameraNode.eulerAngles                  = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
        }
        
        if scenes.count == camerasYawNode.count {
            for i in 0 ..< scenes.count {
                let scene                           = scenes[i]
                let cameraYawNode                   = camerasYawNode[i]
                
                scene.rootNode.addChildNode(cameraYawNode)
            }
        }
        
        leftSceneView?.pointOfView                  = leftCameraNode
        rightSceneView?.pointOfView                 = rightCameraNode
        
        leftSceneView?.playing                      = true
        rightSceneView?.playing                     = true
        
        // Respond to user head movement. Refreshes the position of the camera 60 times per second.
        motionManager                               = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval   = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        
        //Initialize position variable
        currentAngleX                               = 0
        currentAngleY                               = 0
        
        //Launch the player
        play()
        m_pause()
        showText("chargeing...")
        
    }
    
    //MARK: Camera Orientation
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let camerasNodeAngles                       = getCamerasNodeAngle()
        
        for cameraNode in camerasNode {
            cameraNode.eulerAngles                  = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
        }
    }
    
    func getCamerasNodeAngle() -> [Double] {
        
        var camerasNodeAngle1: Double!              = 0.0
        var camerasNodeAngle2: Double!              = 0.0
        
        let orientation = UIApplication.sharedApplication().statusBarOrientation.rawValue
        
        if orientation == 1 {
            camerasNodeAngle1                       = -M_PI_2
        } else if orientation == 2 {
            camerasNodeAngle1                       = M_PI_2
        } else if orientation == 3 {
            camerasNodeAngle1                       = 0.0
            camerasNodeAngle2                       = M_PI
        }
        
        return [ -M_PI_2, camerasNodeAngle1, camerasNodeAngle2]
        
    }
    
    //MARK: Video Player
    func play(){
        NSLog("play!")
        let videoName = "04"
        
        let fileURL: NSURL? = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource(videoName, ofType: "mp4")!)
        
        if let fileURL = fileURL{
            
            var screenScale : CGFloat                                       = 1.0
            if PROCESSOR_64BITS {
                screenScale                                                 = CGFloat(3.0)
            }
            
            player                                                          = AVPlayer(URL: fileURL)
            let videoSpriteKitNodeLeft                                      = SKVideoNode(AVPlayer: player)
            let videoNodeLeft                                               = SCNNode()
            let spriteKitScene1                                             = SKScene(size: CGSize(width: 1280 * screenScale, height: 1280 * screenScale))
            spriteKitScene1.shouldRasterize                                 = true
            var spriteKitScenes                                             = [spriteKitScene1]
            
            videoNodeLeft.geometry                                          = SCNSphere(radius: 30)
            spriteKitScene1.scaleMode                                       = .AspectFit
            videoSpriteKitNodeLeft.position                                 = CGPoint(x: spriteKitScene1.size.width / 2.0, y: spriteKitScene1.size.height / 2.0)
            videoSpriteKitNodeLeft.size                                     = spriteKitScene1.size
            
            let videoSpriteKitNodeRight                                 = SKVideoNode(AVPlayer: player)
            let videoNodeRight                                          = SCNNode()
            let spriteKitScene2                                         = SKScene(size: CGSize(width: 1280 * screenScale, height: 1280 * screenScale))
            spriteKitScene2.shouldRasterize                             = true
            
            videosSpriteKitNode                                         = [videoSpriteKitNodeLeft, videoSpriteKitNodeRight]
            videosNode                                                  = [videoNodeLeft, videoNodeRight]
            spriteKitScenes                                             = [spriteKitScene1, spriteKitScene2]
            
            videoNodeRight.geometry                                     = SCNSphere(radius: 30)
            spriteKitScene2.scaleMode                                   = .AspectFit
            videoSpriteKitNodeRight.position                            = CGPoint(x: spriteKitScene1.size.width / 2.0, y: spriteKitScene1.size.height / 2.0)
            videoSpriteKitNodeRight.size                                = spriteKitScene2.size
            
            let mask                                                    = SKShapeNode(rect: CGRectMake(0, 0, spriteKitScene1.size.width, spriteKitScene1.size.width / 2.0))
            mask.fillColor                                              = SKColor.blackColor()
            spriteKitScene1.addChild(videoSpriteKitNodeLeft)
            spriteKitScene2.addChild(videoSpriteKitNodeRight)
            
            if videosNode.count == spriteKitScenes.count && scenes.count == videosNode.count {
                for i in 0 ..< videosNode.count {
                    weak var spriteKitScene                                         = spriteKitScenes[i]
                    let videoNode                                                   = videosNode[i]
                    let scene                                                       = scenes[i]
                    
                    videoNode.geometry?.firstMaterial?.diffuse.contents             = spriteKitScene
                    videoNode.geometry?.firstMaterial?.doubleSided                  = true
                    
                    // Flip video upside down, so that it's shown in the right position
                    var transform                                                   = SCNMatrix4MakeRotation(Float(M_PI), 0.0, 0.0, 1.0)
                    transform                                                       = SCNMatrix4Translate(transform, 1.0, 1.0, 0.0)
                    
                    videoNode.pivot                                                 = SCNMatrix4MakeRotation(Float(M_PI_2), 0.0, -1.0, 0.0)
                    videoNode.geometry?.firstMaterial?.diffuse.contentsTransform    = transform
                    
                    videoNode.position                                              = SCNVector3(x: 0, y: 0, z: 0)
                    
                    scene.rootNode.addChildNode(videoNode)
                }
            }
        }
    }
    
    func m_togglePlayPause() {
        
        if playingVideo {
            m_pause()
        } else {
            m_play()
        }
    }
    
    func m_pause(){
        NSLog("pause")
        showText("pause...",duration: 1)
        for videoSpriteKitNode in videosSpriteKitNode {
            videoSpriteKitNode.pause()
        }
        
        playingVideo = false
    }
    
    func m_play() {
        NSLog("play")
        showText("play!",duration: 1)
//        player.play()
        for videoSpriteKitNode in videosSpriteKitNode {
            videoSpriteKitNode.play()
        }
        playingVideo = true
    }
    
    override func onSetupCompleted() {
        NSLog("setupCompleted")
    }
    
    override func onTap() {
        m_togglePlayPause()
    }
    
    
    //MARK: Render the scene
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval){
        // Render the scene
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            if let strongSelf = self {
                if let mm = strongSelf.motionManager, let motion = mm.deviceMotion {
                    let currentAttitude                                     = motion.attitude
                    
                    var roll : Double                                       = currentAttitude.roll
                    
                    if(UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight) {
                        roll                                                = -1.0 * (-M_PI - roll)
                    }
                    
                    for cameraRollNode in strongSelf.camerasRollNode {
                        cameraRollNode.eulerAngles.x                        = Float(roll) - strongSelf.currentAngleY
                    }
                    
                    for cameraPitchNode in strongSelf.camerasPitchNode {
                        cameraPitchNode.eulerAngles.z                       = Float(currentAttitude.pitch)
                    }
                    
                    for cameraYawNode in strongSelf.camerasYawNode {
                        cameraYawNode.eulerAngles.y                         = Float(currentAttitude.yaw) + strongSelf.currentAngleX
                    }
                }
            }
        }
    }
    override func onDoubleTap() {
        NSLog("currentTime:\(CMTimeGetSeconds(player.currentTime()))")
    }
    
    var scrollRad:CGFloat = 0
    override func onScroll(rad: CGFloat) {
        NSLog("scroll:\(rad) total : \(scrollRad)")
        showText("seek to \(scrollRad / 10.0) second ?")
        scrollRad += rad
    }
    override func onScrollFinish() {
        showText("seek !")
        let seekTime = scrollRad / 10.0
        var currentTime:Float64 = CMTimeGetSeconds(player.currentTime())
//        NSLog("seek time : \(seekTime) current :\(currentTime)")
        currentTime += Float64(seekTime)
//        NSLog("targetTime :\(currentTime)")
        
        player.seekToTime(CMTimeMakeWithSeconds(currentTime,Int32(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        scrollRad = 0
//        NSLog("currentTime:\(CMTimeGetSeconds(player.currentTime()))")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = (view.bounds.width > view.bounds.height) ? view.bounds.width : view.bounds.height;
        
        widthSceneConstraint?.constant = width / 2.0
        heightSceneConstraint?.constant = width / 2.0
    }
    
    func showText(message: String,duration: NSTimeInterval = 0) {
        rightLabel.alpha = 1
        leftLabel.alpha = 1
        
        rightLabel.text = message
        leftLabel.text = message
        
        if duration == 0 {
            return
        }
        
        UIView.animateWithDuration(duration, animations: {
                self.rightLabel.alpha = 0
                self.leftLabel.alpha = 0
            })
    }
    
    
    //MARK: Clean perf
    deinit {
        
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
        
        playingVideo = false
        
        for videoSKNode in videosSpriteKitNode {
            videoSKNode.removeFromParent()
        }
        
        for scene in scenes {
            for node in scene.rootNode.childNodes {
                removeNode(node)
            }
        }
        
    }
    
    func removeNode(node : SCNNode) {
        
        for node in node.childNodes {
            removeNode(node)
        }
        
        if 0 == node.childNodes.count {
            node.removeFromParentNode()
        }
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}