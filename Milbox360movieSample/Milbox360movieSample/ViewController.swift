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
    var activateStereoscopicVideo                   : Bool = false
    
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
        
        leftSceneView.scene                         = scene1
        
        if true == activateStereoscopicVideo {
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
        } else {
            scenes                                  = [scene1]
            camerasNode                             = [cameraNodeLeft]
            camerasRollNode                         = [cameraRollNodeLeft]
            camerasPitchNode                        = [cameraPitchNodeLeft]
            camerasYawNode                          = [cameraYawNodeLeft]
            rightSceneView?.scene                   = scene1
        }
        
        leftCameraNode.position                     = SCNVector3(x: 0 - (activateStereoscopicVideo ? 0.0 : 0.5), y: 0, z: 0)
        rightCameraNode.position                    = SCNVector3(x: 0 + (activateStereoscopicVideo ? 0.0 : 0.5), y: 0, z: 0)
        
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
        
    }
    
    //MARK: Camera Orientation
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let camerasNodeAngles                       = getCamerasNodeAngle()
        
//        widthSceneConstraint?.active                = (.Portrait != toInterfaceOrientation && .PortraitUpsideDown != toInterfaceOrientation)
//        heightSceneConstraint?.active               = (.Portrait == toInterfaceOrientation || .PortraitUpsideDown == toInterfaceOrientation)
        
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
        NSLog("プレイ")
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
            
//            videoNodeLeft.geometry                                          = SCNSphere(radius: 30)
            videoNodeLeft.geometry = SCNPlane(width: 20, height: 20)
            spriteKitScene1.scaleMode                                       = .AspectFit
            videoSpriteKitNodeLeft.position                                 = CGPoint(x: spriteKitScene1.size.width / 2.0, y: spriteKitScene1.size.height / 2.0)
            videoSpriteKitNodeLeft.size                                     = spriteKitScene1.size
            
            if true == activateStereoscopicVideo {
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
                
                let cropNode                                                = SKCropNode()
                cropNode.maskNode                                           = mask
                
                cropNode.addChild(videoSpriteKitNodeLeft)
                cropNode.yScale                                             = 2
                cropNode.position                                           = CGPoint(x: 0, y: 0)
                
                let mask2                                                   = SKShapeNode(rect: CGRectMake(0, spriteKitScene1.size.width / 2.0, spriteKitScene1.size.width, spriteKitScene1.size.width / 2.0))
                mask2.fillColor                                             = SKColor.blackColor()
                let cropNode2                                               = SKCropNode()
                cropNode2.maskNode                                          = mask2
                
                cropNode2.addChild(videoSpriteKitNodeRight)
                cropNode2.yScale                                            = 2
                cropNode2.position                                          = CGPoint(x: 0, y: -spriteKitScene1.size.width)
                
                spriteKitScene1.addChild(cropNode2)
                spriteKitScene2.addChild(cropNode)
                
            } else {
                videosSpriteKitNode                                         = [videoSpriteKitNodeLeft]
                videosNode                                                  = [videoNodeLeft]
                
                spriteKitScene1.addChild(videoSpriteKitNodeLeft)
            }
            
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
                    
                    videoNode.position                                              = SCNVector3(x: 10, y: 0, z: 0)//x:0
                    
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
        NSLog("ポース")
//        player.pause()
        for videoSpriteKitNode in videosSpriteKitNode {
            videoSpriteKitNode.pause()
        }
        
        playingVideo = false
    }
    
    func m_play() {
        NSLog("再開")
//        player.play()
        for videoSpriteKitNode in videosSpriteKitNode {
            videoSpriteKitNode.play()
        }
        playingVideo = true
    }
    
    override func onSetupCompleted() {
        NSLog("初期化完了")
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
    
    override func onScroll(rad: CGFloat) {
        NSLog("スクロール:\(rad)")
        
        var currentTime:Float64 = CMTimeGetSeconds(player.currentTime())
        currentTime += Float64(rad)
        player.seekToTime(CMTimeMakeWithSeconds(currentTime,Int32(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = (view.bounds.width > view.bounds.height) ? view.bounds.width : view.bounds.height;
        
        widthSceneConstraint?.constant = width / 2.0
        heightSceneConstraint?.constant = width / 2.0
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