//
//  GameViewController.swift
//  MilboxTouchSample
//
//  Created by TakumiOhtani on 2016/05/30.
//  Copyright (c) 2016年 white. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import MilboxTouch

class GameViewController: MBTViewController {
    var textView: SCNText?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene()
        
        // create and add a camera t the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x:0, y:0, z:90)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x:0, y:10, z:10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        let textNode = SCNNode()
        textView = SCNText(string: "test", extrusionDepth: 0)
        textView?.alignmentMode = kCAAlignmentCenter
        textView?.font = UIFont (name: "Arial", size: 3)
        textNode.geometry = textView
        textNode.position = SCNVector3(-15, -5, 0)
        scene.rootNode.addChildNode(textNode)
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named:"texture")
        material.specular.contents = UIColor.grayColor()
        material.locksAmbientWithDiffuse = true
        
//         animate the 3D object
//        let animation:CABasicAnimation = CABasicAnimation(keyPath:"rotation")
//        animation.toValue = NSValue(SCNVector4:SCNVector4(x:0, y:1, z:0, w:Float(M_PI) * 2))
//        animation.duration = 5
//        animation.repeatCount = MAXFLOAT // repeat forever
//        textNode.addAnimation(animation, forKey:nil)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    override func onTap() {
        textView?.string = "タップ！"
    }
    override func onDoubleTap() {
        textView?.string = "ダブルタップ！"
    }
    override func onScroll(rad: CGFloat) {
        textView?.string = "スクロール（\(rad)度）"
    }

}
