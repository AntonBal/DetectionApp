//
//  ViewController.swift
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

import ARKit

class ViewController: UIViewController {

    let detector = BodyDetector()
    
    var sceneView: ARSCNView {
        return view as! ARSCNView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configScene()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let session = ARWorldTrackingConfiguration()
        sceneView.session.run(session)
        
        
        addPlane(for: .zero)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func configScene() {
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.showsStatistics = true
        sceneView.session.delegate = self
    }
    
    var planeNode: SCNNode?
    
    func addPlane(for rect: CGRect) {
        
        guard self.planeNode == nil else {
            self.planeNode?.position = SCNVector3(0.1, 0.1, 1)
            return
        }
        
        let plane = SCNPlane(width: 1, height: 1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.fillMode = .lines
        plane.firstMaterial = material
        
        let planeNode = SCNNode()
        planeNode.geometry = plane
        planeNode.position = SCNVector3(-0.5, 0.1, -3)
        plane.cornerRadius = 3
        
        sceneView.scene.rootNode.addChildNode(planeNode)
        self.planeNode = planeNode
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
       
        guard let frame = session.currentFrame else { return }
        
        detector.detectImageRef(frame.capturedImage) { (value) in
            guard let body = value else { return }

            print("FOUND HEAD", body.head)
            print("FOUND HEAD", body.shoulders)
            self.addPlane(for: body.head)
        }
    }
}

extension ViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
}
