//
//  ViewController.swift
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

import ARKit
import SceneKit

class RectangleNode: SCNNode {
    
    init(center: SCNVector3, width: CGFloat, height: CGFloat, orientation: Float) {
        super.init()
        
        // Create the 3D plane geometry with the dimensions calculated from corners
        let planeGeometry = SCNPlane(width: width, height: height)
        let rectNode = SCNNode(geometry: planeGeometry)
        
        // Planes in SceneKit are vertical by default so we need to rotate
        // 90 degrees to match planes in ARKit
        var transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        // Set rotation to the corner of the rectangle
        transform = SCNMatrix4Rotate(transform, orientation, 0, 1, 0)
        
        rectNode.transform = transform
        
        // We add the new node to ourself since we inherited from SCNNode
        self.addChildNode(rectNode)
        
        // Set position to the center of rectangle
        self.position = center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
//        session.worldAlignment = .gravityAndHeading
        sceneView.session.run(session)
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
    
    func addPlane(for position: SCNVector3, width: CGFloat, height: CGFloat, simdTransform: simd_float4x4) {
        
        guard self.planeNode == nil else {
            self.planeNode?.position = position
//            self.planeNode?.simdTransform = simdTransform
            return
        }
        
        let plane = SCNPlane(width: width, height: height)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
//        material.fillMode = .lines
        plane.firstMaterial = material
        
        let planeNode = SCNNode()
        planeNode.geometry = plane
        planeNode.position = position
//        planeNode.simdTransform = simdTransform
        sceneView.scene.rootNode.addChildNode(planeNode)
        self.planeNode = planeNode
    }
    
    func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
       
        guard let frame = session.currentFrame else { return }
        
        detector.detectImageRef(frame.capturedImage, size: sceneView.frame.size, scale: 2) { [weak self] (value) in
            guard let sSelf = self, let body = value else { return }
            
            let rect = body.head.applying(CGAffineTransform.identity.scaledBy(x: 2, y: 2))
            
            let newRect = CGRect(x: rect.minX - sSelf.sceneView.frame.midX, y: rect.minY - sSelf.sceneView.frame.midY, width: rect.width, height: rect.height)
            print(newRect)
            
            let x = newRect.minX / sSelf.sceneView.frame.width
            let y = newRect.minY / sSelf.sceneView.frame.height
            let width = newRect.width / sSelf.sceneView.frame.width
            let height = newRect.height / sSelf.sceneView.frame.height
            
//            let position = sSelf.sceneView.convert(newRect.origin, from: nil)
//            let objectPosition = float4(Float(position.x), Float(position.y), -1, 1)
//            let myTransform = sSelf.sceneView.pointOfView!.simdTransform
//            let objectTransform = sSelf.translationMatrix(with: myTransform, for: objectPosition)
//            sSelf.sceneView.pointOfView?.simdConvertPosition(float3(Float(position.x), Float(position.y), -1), to: nil)
            
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -1
            
//            sSelf.sceneView.pointOfView?.convertPosition(SCNVector3(position.x, position.y, -1), to: nil)
            
            print("transform ", frame.camera.transform)
            print("FOUND HEAD", CGRect(x: x, y: y, width: width, height: height) )
            sSelf.addPlane(for: SCNVector3(x, y, -1), width: width, height: height, simdTransform: matrix_multiply(frame.camera.transform, translation))
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
