//
//  ViewController.swift
//  EducationAR
//
//  Created by Dhruva barua on 7/8/22.
//

import UIKit
import SceneKit //Needed for 3D object projects, or you could use RealityKit, much more recent
import ARKit // Apple's AR Library; Google's is called ARCore

public var currentRadius: Float = 0 //Radius for photo resist

var daswitch = 0

public var homescreenStatus: Bool = true //Checks if LCD on home screen

public var waferNode: SCNNode? //wafer
public var screenNode: SCNNode? //lcd screen
public var frameNode: SCNNode? //lcd frame
public var innerNode: SCNNode? //inner bullseye for accuracy of centering of wafer
public var middleNode: SCNNode?
public var outerNode: SCNNode?
public var hitNode: SCNNode? //little transparent stick in middle of the wafer that makes contact with transparent bullseye positioned at center of spin coater for centering wafer

//These are all the bullseye mid and outer nodes that make up the bullseye (rings of rectangles for accuracy)
public var mid1: SCNNode?
public var mid2: SCNNode?
public var mid3: SCNNode?
public var mid4: SCNNode?
public var mid5: SCNNode?
public var mid6: SCNNode?
public var mid7: SCNNode?
public var mid8: SCNNode?
public var mid9: SCNNode?
public var mid10: SCNNode?
public var mid11: SCNNode?
public var mid12: SCNNode?
public var out1: SCNNode?
public var out2: SCNNode?
public var out3: SCNNode?
public var out4: SCNNode?
public var out5: SCNNode?
public var out6: SCNNode?
public var out7: SCNNode?
public var out8: SCNNode?
public var out9: SCNNode?
public var out10: SCNNode?
public var out11: SCNNode?
public var out12: SCNNode?
public var out13: SCNNode?
public var out14: SCNNode?
public var out15: SCNNode?
public var out16: SCNNode?
public var out17: SCNNode?
public var out18: SCNNode?

public var liquidNode = SCNNode(geometry: SCNCylinder(radius: 0, height: 0.8)) //liquid to be poured onto the wafer, transparent for now
public var spreadState = false //checks if photo resist should spread

//inner ring of the bullseye, innerNode is the very middle/center
public var in1: SCNNode?
public var in2: SCNNode?
public var in3: SCNNode?
public var in4: SCNNode?
public var in5: SCNNode?
public var in6: SCNNode?
public var in7: SCNNode?
public var in8: SCNNode?

//arrays of the nodes making up the outter, middle and middle inner rings of the bullseye
public var midNodes: [SCNNode]!
public var outNodes: [SCNNode]!
public var inNodes: [SCNNode]!

public var arScene: SCNScene? //the AR Scene that the camera is showing in the app

public var centerStage = 0 //checks how well centered  the wafer is
public var currentCenterStage = 0 //after user presses C, that centerstage is the current center stage, so it doesn't change while animating

//parameters
public var rpm1: Double = 1000
public var time1: Double = 10
public var rpm2: Double = 2000
public var time2: Double = 20
public var vacuumState = false

public var timeDuration1: Double? = time1 //for timer
public var timeDuration2: Double? = time2 // for second stage timer

public var spinStage2 = false //is stage 2 supposed to run yet?

//title text on the lcd screen
private var text = SCNText(string: "Welcome", extrusionDepth: 1)
private var textNode = SCNNode(geometry: text)

//paragraph text on the lower half of the lcd screen
private var text2 = SCNText(string: "--", extrusionDepth: 1)
private var textNode2 = SCNNode(geometry: text2)

private var pwrStatus: Bool = false //is the LCD on? Power switch via arduino enables this

private var concatenatedInput: String = "" //used to convert text on the text2 onto here and make it a number

//timers for stage 1 and stage 2 spins
var timer1: Timer?
var timer2: Timer?

//enum for different cases of physics contact with hitNode to see which section of the bullseye the wafer center (hitNode) hit
enum BodyType: Int {
    case wafer = 1
    case spinnerOuter = 2
    case spinnerMiddle = 4
    case spinnerSemiInner = 8
    case spinnerInner = 16
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
 
    @IBOutlet weak var sceneView: ARSCNView! //sceneView for each eye (split screen into 2)
    @IBOutlet weak var sceneView2: ARSCNView!
    
    
    //run when viewController class is loaded onto da screen, lode in all instantiate scenes, nodes into the scene programatically, position nodes, and set background to black
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
        //sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
        
        sceneView.autoenablesDefaultLighting = true
        let lcdScene = SCNScene(named: "art.scnassets/lcd.scn")! //scene for lcd screen nodes and the bullseye since it's positioned relative to the lcd screen
        let waferScene = SCNScene(named: "art.scnassets/wafer.scn")! //scene for the wafer which includes the hitNode at its center that tracks if it has come into physical contact with the transparent virtual bullseye
        liquidNode.pivot = SCNMatrix4MakeTranslation(0, 0, 0) //make liquid in center of barcode
        liquidNode.geometry?.materials.map({ material in
            material.diffuse.contents = UIColor.red.withAlphaComponent(0) //make liquid red and transparent for beginning
        })
        
        //instantiating node variables with where they are in scenes (childnodes under the root node)
        screenNode = lcdScene.rootNode.childNodes[1]
        frameNode = lcdScene.rootNode.childNodes[0]
        innerNode = lcdScene.rootNode.childNode(withName: "cylinder1", recursively: true)
        middleNode = lcdScene.rootNode.childNode(withName: "cylinder2", recursively: true)
        outerNode = lcdScene.rootNode.childNode(withName: "cylinder3", recursively: true)
        hitNode = waferScene.rootNode.childNode(withName: "sphere", recursively: true)
        waferNode = waferScene.rootNode.childNode(withName: "empty", recursively: true)?.childNodes[0]
        waferNode?.addChildNode(liquidNode)
        mid1 = lcdScene.rootNode.childNode(withName: "mid1", recursively: true)
        mid2 = lcdScene.rootNode.childNode(withName: "mid2", recursively: true)
        mid3 = lcdScene.rootNode.childNode(withName: "mid3", recursively: true)
        mid4 = lcdScene.rootNode.childNode(withName: "mid4", recursively: true)
        mid5 = lcdScene.rootNode.childNode(withName: "mid5", recursively: true)
        mid6 = lcdScene.rootNode.childNode(withName: "mid6", recursively: true)
        mid7 = lcdScene.rootNode.childNode(withName: "mid7", recursively: true)
        mid8 = lcdScene.rootNode.childNode(withName: "mid8", recursively: true)
        mid9 = lcdScene.rootNode.childNode(withName: "mid9", recursively: true)
        mid10 = lcdScene.rootNode.childNode(withName: "mid10", recursively: true)
        mid11 = lcdScene.rootNode.childNode(withName: "mid11", recursively: true)
        mid12 = lcdScene.rootNode.childNode(withName: "mid12", recursively: true)
        out1 = lcdScene.rootNode.childNode(withName: "out1", recursively: true)
        out2 = lcdScene.rootNode.childNode(withName: "out2", recursively: true)
        out3 = lcdScene.rootNode.childNode(withName: "out3", recursively: true)
        out4 = lcdScene.rootNode.childNode(withName: "out4", recursively: true)
        out5 = lcdScene.rootNode.childNode(withName: "out5", recursively: true)
        out6 = lcdScene.rootNode.childNode(withName: "out6", recursively: true)
        out7 = lcdScene.rootNode.childNode(withName: "out7", recursively: true)
        out8 = lcdScene.rootNode.childNode(withName: "out8", recursively: true)
        out9 = lcdScene.rootNode.childNode(withName: "out9", recursively: true)
        out10 = lcdScene.rootNode.childNode(withName: "out10", recursively: true)
        out11 = lcdScene.rootNode.childNode(withName: "out11", recursively: true)
        out12 = lcdScene.rootNode.childNode(withName: "out12", recursively: true)
        out13 = lcdScene.rootNode.childNode(withName: "out13", recursively: true)
        out14 = lcdScene.rootNode.childNode(withName: "out14", recursively: true)
        out15 = lcdScene.rootNode.childNode(withName: "out15", recursively: true)
        out16 = lcdScene.rootNode.childNode(withName: "out16", recursively: true)
        out17 = lcdScene.rootNode.childNode(withName: "out17", recursively: true)
        out18 = lcdScene.rootNode.childNode(withName: "out18", recursively: true)
        
        in1 = lcdScene.rootNode.childNode(withName: "in1", recursively: true)
        in2 = lcdScene.rootNode.childNode(withName: "in2", recursively: true)
        in3 = lcdScene.rootNode.childNode(withName: "in3", recursively: true)
        in4 = lcdScene.rootNode.childNode(withName: "in4", recursively: true)
        in5 = lcdScene.rootNode.childNode(withName: "in5", recursively: true)
        in6 = lcdScene.rootNode.childNode(withName: "in6", recursively: true)
        in7 = lcdScene.rootNode.childNode(withName: "in7", recursively: true)
        in8 = lcdScene.rootNode.childNode(withName: "in8", recursively: true)
         

        
        midNodes = [mid1!, mid2!, mid3!, mid4!, mid5!, mid6!, mid7!, mid8!, mid9!, mid10!, mid11!, mid12!]
        outNodes = [out1!, out2!, out3!, out4!, out5!, out6!, out7!, out8!, out9!, out10!, out11!, out12!, out13!, out14!, out15!, out16!, out17!, out18!]
        inNodes = [in1!, in2!, in3!, in4!, in5!, in6!, in7!, in8!]

        arScene = SCNScene()
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        sceneView.scene = arScene!
        sceneView.scene.physicsWorld.contactDelegate = self
                
        // Set up SceneView2 (Right Eye)
        sceneView2.scene = arScene!
        sceneView2.scene.physicsWorld.contactDelegate = self
        sceneView2.showsStatistics = sceneView.showsStatistics
        sceneView2.isPlaying = true
        
        view.backgroundColor = UIColor.black //black background (dont mind this tbh)
    }
    
    //configure AR aspect of the app
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ar tracking config, set to world tracking to access occlusion
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.frameSemantics.insert(.personSegmentationWithDepth) //occlusion!

        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "QR Codes", bundle: Bundle.main) {
            configuration.detectionImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 2
        }
        configuration.frameSemantics.insert(.personSegmentationWithDepth)

        sceneView.session.run(configuration)
    }
    
    //when view disappears, pause scene
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // UPDATE EVERY FRAME:
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFrame()
        }
    }
    
    //every frame, split screen to two duplicate screen views for each eye for a headset
    
    func updateFrame() {
                
        // Clone pointOfView for Second View
        let pointOfView : SCNNode = (sceneView.pointOfView?.clone())! // just clone point of view onto second screen, dont mind bottom comment as lense for the headset adjusts it already
        /*
        // Determine Adjusted Position for Right Eye
        let orientation : SCNQuaternion = pointOfView.orientation
        let orientationQuaternion : GLKQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let eyePos : GLKVector3 = GLKVector3Make(1.0, 0.0, 0.0)
        let rotatedEyePos : GLKVector3 = GLKQuaternionRotateVector3(orientationQuaternion, eyePos)
        let rotatedEyePosSCNV : SCNVector3 = SCNVector3Make(rotatedEyePos.x, rotatedEyePos.y, rotatedEyePos.z)
        
        let mag : Float = 0.066 // This is the value for the distance between two pupils (in metres). The Interpupilary Distance (IPD).
        pointOfView.position.x += rotatedEyePosSCNV.x * mag
        pointOfView.position.y += rotatedEyePosSCNV.y * mag
        pointOfView.position.z += rotatedEyePosSCNV.z * mag
        */
        // Set PointOfView for SecondView
        sceneView2.pointOfView = pointOfView
        
    }
    
    //if 3d bullseye on spin coater touches center of wafer, contactNode is center of wafer, and depending on which layer it hits of the bullseye, mark its accuracy from 1-4, 4 most accurate. and make wobble dependent on that.
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var contactNode: SCNNode?
        //checks for which bullseye section is hit and calls that contactNode
        if (contact.nodeA.name == "wafer") {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        //centerstage for respective bullseye section, 4 is most accurate, the bull's eye, but 1 is least accurate, outer ring, 0 means wafer not placed yet
        
        switch contactNode?.physicsBody?.categoryBitMask {
            case BodyType.spinnerInner.rawValue:
                centerStage = 4
                break
            case BodyType.spinnerSemiInner.rawValue:
                centerStage = 3
                break
            case BodyType.spinnerMiddle.rawValue:
                centerStage = 2
                break
            case BodyType.spinnerOuter.rawValue:
                centerStage = 1
                break
            default:
                break
        }
        print(centerStage)
    }
    
    //whenever an image anchor is scanned, display nodes on or whatever position away from them, like for the different barcodes. Also set their physics bodies so that xcode can detect physical collisions and contact between center of wafer, hitNode, and the layers.
    
    var physics = false
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        if (physics == false) {
            //set up hitNode as a physics body to detect contact with bullseye

            hitNode?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: hitNode!))
            hitNode?.physicsBody?.isAffectedByGravity = false
            hitNode?.physicsBody?.categoryBitMask = BodyType.wafer.rawValue //defines it as the wafer in the enum
            hitNode?.physicsBody?.contactTestBitMask = BodyType.spinnerInner.rawValue | BodyType.spinnerMiddle.rawValue | BodyType.spinnerOuter.rawValue | BodyType.spinnerSemiInner.rawValue //wafer center hitNode can hit all of the rings in the enum
            
            innerNode?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)

            //set physical bodies for each rectangle that makes up the 3d bullseye so that they can detect contact
            for inner in inNodes {
                inner.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
                inner.physicsBody?.isAffectedByGravity = false
                inner.physicsBody?.categoryBitMask = BodyType.spinnerSemiInner.rawValue
                inner.physicsBody?.contactTestBitMask = BodyType.wafer.rawValue
            }

            for mid in midNodes {
                mid.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
                mid.physicsBody?.isAffectedByGravity = false
                mid.physicsBody?.categoryBitMask = BodyType.spinnerMiddle.rawValue
                mid.physicsBody?.contactTestBitMask = BodyType.wafer.rawValue
            }
            for out in outNodes {
                out.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
                out.physicsBody?.isAffectedByGravity = false
                out.physicsBody?.categoryBitMask = BodyType.spinnerOuter.rawValue
                out.physicsBody?.contactTestBitMask = BodyType.wafer.rawValue
            }
            innerNode?.physicsBody?.isAffectedByGravity = false
            innerNode?.physicsBody?.categoryBitMask = BodyType.spinnerInner.rawValue
            innerNode?.physicsBody?.contactTestBitMask = BodyType.wafer.rawValue
            
            
            print("added physics bodies")
            physics = true
        }
        
        
        //detecting image and putting a lil transparent plane on it, then putting the rest of images on it based on QR Codes
 
        if let imageAnchor = anchor as? ARImageAnchor {
            print("Anchor from an Image Detected.")
            let size = imageAnchor.referenceImage.physicalSize
            let plane = SCNPlane(width: size.width, height: size.height)
            plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            plane.cornerRadius = 0.005
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi/2
            node.addChildNode(planeNode)
            
            var shapeNode: SCNNode?
            var shapeNode2: SCNNode?
            var shapeNode3: SCNNode?
            var shapeNode4: SCNNode?
            var shapeNode5: SCNNode?
            var shapeNode6: SCNNode?
            var shapeNode7: SCNNode?
            var shapeNode8: SCNNode?
            var shapeNode9: SCNNode?
            var shapeNode10: SCNNode?
            var shapeNode11: SCNNode?
            var shapeNode12: SCNNode?
            var shapeNode13: SCNNode?
            var shapeNode14: SCNNode?
            var shapeNode15: SCNNode?
            var shapeNode16: SCNNode?
            var shapeNode17: SCNNode?
            var shapeNode18: SCNNode?
            var shapeNode19: SCNNode?
            var shapeNode20: SCNNode?
            var shapeNode21: SCNNode?
            var shapeNode22: SCNNode?
            var shapeNode23: SCNNode?
            var shapeNode24: SCNNode?
            var shapeNode25: SCNNode?
            var shapeNode26: SCNNode?
            var shapeNode27: SCNNode?
            var shapeNode28: SCNNode?
            var shapeNode29: SCNNode?
            var shapeNode30: SCNNode?
            var shapeNode31: SCNNode?
            var shapeNode32: SCNNode?
            var shapeNode33: SCNNode?

            var shapeNode34: SCNNode?
            var shapeNode35: SCNNode?
            var shapeNode36: SCNNode?
            var shapeNode37: SCNNode?
            var shapeNode38: SCNNode?
            var shapeNode39: SCNNode?
            var shapeNode40: SCNNode?
            var shapeNode41: SCNNode?
            
            //if wafer barcode is detected...
            
            if (imageAnchor.referenceImage.name == "qrcode1") {
                shapeNode = waferNode

                
                shapeNode2 = hitNode
                shapeNode3 = liquidNode
                guard let shape = shapeNode else { return nil }
                guard let shape2 = shapeNode2 else { return nil }
                guard let shape3 = shapeNode3 else { return nil }
                node.addChildNode(shape)
                node.addChildNode(shape2)
                node.addChildNode(shape3)
            } else if (imageAnchor.referenceImage.name == "qrcode2"){ //if screen barcode is detected...
                shapeNode = screenNode
                shapeNode2 = frameNode
                
                //same as hitNode with the bullseye made of tiny rectangles since a hollow cylinder is too complex for xcode. set them all to same type at that the only thing they can come into contact with is the hitNode, or the "wafer" category in the bodytype enum
                
                //display all nodes
                shapeNode3 = innerNode
                shapeNode4 = midNodes[0]
                shapeNode5 = midNodes[1]
                shapeNode6 = midNodes[2]
                shapeNode7 = midNodes[3]
                shapeNode8 = midNodes[4]
                shapeNode9 = midNodes[5]
                shapeNode10 = midNodes[6]
                shapeNode11 = midNodes[7]
                shapeNode12 = midNodes[8]
                shapeNode13 = midNodes[9]
                shapeNode14 = midNodes[10]
                shapeNode15 = midNodes[11]
                shapeNode16 = outNodes[0]
                shapeNode17 = outNodes[1]
                shapeNode18 = outNodes[2]
                shapeNode19 = outNodes[3]
                shapeNode20 = outNodes[4]
                shapeNode21 = outNodes[5]
                shapeNode22 = outNodes[6]
                shapeNode23 = outNodes[7]
                shapeNode24 = outNodes[8]
                shapeNode25 = outNodes[9]
                shapeNode26 = outNodes[10]
                shapeNode27 = outNodes[11]
                shapeNode28 = outNodes[12]
                shapeNode29 = outNodes[13]
                shapeNode30 = outNodes[14]
                shapeNode31 = outNodes[15]
                shapeNode32 = outNodes[16]
                shapeNode33 = outNodes[17]
    
                shapeNode34 = inNodes[0]
                shapeNode35 = inNodes[1]
                shapeNode36 = inNodes[2]
                shapeNode37 = inNodes[3]
                shapeNode38 = inNodes[4]
                shapeNode39 = inNodes[5]
                shapeNode40 = inNodes[6]
                shapeNode41 = inNodes[7]

                guard let shape = shapeNode else { return nil}
                guard let shape2 = shapeNode2 else { return nil }
                guard let shape3 = shapeNode3 else { return nil }
                guard let shape4 = shapeNode4 else { return nil }
                guard let shape5 = shapeNode5 else { return nil }
                guard let shape6 = shapeNode6 else { return nil }
                guard let shape7 = shapeNode7 else { return nil }
                guard let shape8 = shapeNode8 else { return nil }
                guard let shape9 = shapeNode9 else { return nil }
                guard let shape10 = shapeNode10 else { return nil }
                guard let shape11 = shapeNode11 else { return nil }
                guard let shape12 = shapeNode12 else { return nil }
                guard let shape13 = shapeNode13 else { return nil }
                guard let shape14 = shapeNode14 else { return nil }
                guard let shape15 = shapeNode15 else { return nil }
                guard let shape16 = shapeNode16 else { return nil }
                guard let shape17 = shapeNode17 else { return nil }
                guard let shape18 = shapeNode18 else { return nil }
                guard let shape19 = shapeNode19 else { return nil }
                guard let shape20 = shapeNode20 else { return nil }
                guard let shape21 = shapeNode21 else { return nil }
                guard let shape22 = shapeNode22 else { return nil }
                guard let shape23 = shapeNode23 else { return nil }
                guard let shape24 = shapeNode24 else { return nil }
                guard let shape25 = shapeNode25 else { return nil }
                guard let shape26 = shapeNode26 else { return nil }
                guard let shape27 = shapeNode27 else { return nil }
                guard let shape28 = shapeNode28 else { return nil }
                guard let shape29 = shapeNode29 else { return nil }
                guard let shape30 = shapeNode30 else { return nil }
                guard let shape31 = shapeNode31 else { return nil }
                guard let shape32 = shapeNode32 else { return nil }
                guard let shape33 = shapeNode33 else { return nil }
    
                guard let shape34 = shapeNode34 else { return nil }
                guard let shape35 = shapeNode35 else { return nil }
                guard let shape36 = shapeNode36 else { return nil }
                guard let shape37 = shapeNode37 else { return nil }
                guard let shape38 = shapeNode38 else { return nil }
                guard let shape39 = shapeNode39 else { return nil }
                guard let shape40 = shapeNode40 else { return nil }
                guard let shape41 = shapeNode41 else { return nil }
    
                
                node.addChildNode(shape)
                node.addChildNode(shape2)
                node.addChildNode(shape3)
                node.addChildNode(shape4)
                node.addChildNode(shape5)
                node.addChildNode(shape6)
                node.addChildNode(shape7)
                node.addChildNode(shape8)
                node.addChildNode(shape9)
                node.addChildNode(shape10)
                node.addChildNode(shape11)
                node.addChildNode(shape12)
                node.addChildNode(shape13)
                node.addChildNode(shape14)
                node.addChildNode(shape15)
                node.addChildNode(shape16)
                node.addChildNode(shape17)
                node.addChildNode(shape18)
                node.addChildNode(shape19)
                node.addChildNode(shape20)
                node.addChildNode(shape21)
                node.addChildNode(shape22)
                node.addChildNode(shape23)
                node.addChildNode(shape24)
                node.addChildNode(shape25)
                node.addChildNode(shape26)
                node.addChildNode(shape27)
                node.addChildNode(shape28)
                node.addChildNode(shape29)
                node.addChildNode(shape30)
                node.addChildNode(shape31)
                node.addChildNode(shape32)
                node.addChildNode(shape33)

                node.addChildNode(shape34)
                node.addChildNode(shape35)
                node.addChildNode(shape36)
                node.addChildNode(shape37)
                node.addChildNode(shape38)
                node.addChildNode(shape39)
                node.addChildNode(shape40)
                node.addChildNode(shape41)
    
            }
        }
        return node
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor, imageAnchor.isTracked == false {
            print("removed anchor")
            sceneView?.session.remove(anchor: anchor)
            hitNode?.physicsBody = nil
            innerNode?.physicsBody = nil
            
            for inner in inNodes {
                inner.physicsBody = nil
            }

            for mid in midNodes {
                mid.physicsBody = nil
            }
            for out in outNodes {
                out.physicsBody = nil
            }
            physics = false
        }
    }
}

let maxPressure = 1000.0 //max pressure value from pressure sensor
let constant: Float = 0.03 //constant to visually keep liquid pouring at a not too fast or slow rate
var liquidHeight = 0.2

var spinningStatus = false //checks if wafer is spinning

//function that gets pressure sensor data every millisecond or so and sprays liquid to a certain radius

public func readPressure(input: Float) {
    if (currentRadius < 0.7) { // pour liquid until radius of liquid on wafer is 0.7
        if (input > 5) {
            currentRadius = Float(currentRadius + (input/Float(maxPressure))*constant)
            liquidNode.geometry = SCNCylinder(radius: CGFloat(currentRadius), height: liquidHeight)//what u have to do in xcode is reapply the currentRadius of the liquid to a new cylinder and make it red like below so its like making new liquid copies every second but getting bigger and bigger
            liquidNode.geometry?.materials.map({ material in
                material.diffuse.contents = UIColor.red
            })
        }
    }
    if (spinningStatus) { //if wafer spinning, spread liquid out and once its done spreading remove it and instantly make the whole wafer red!
        if (spreadState == true) {
            liquidNode.pivot = SCNMatrix4MakeTranslation(0, -0.05, 0)
            if (currentRadius > 0) {
                if (currentRadius >= 0.7 && currentRadius < 1.48) { // increase radius of liquid
                    currentRadius += 0.15
                    liquidNode.geometry = SCNCylinder(radius: CGFloat(currentRadius), height: liquidHeight)
                    liquidNode.geometry?.materials.map({ material in
                        material.diffuse.contents = UIColor.red.withAlphaComponent(1)
                    })
                } else if (currentRadius >= 0.7) { //once liquid is spread, turn wafer red and remove liquidNode
                    liquidNode.removeFromParentNode()
                    waferNode!.geometry?.materials.map({ material in
                        material.diffuse.contents = UIColor.red
                    })
                }
                if (liquidHeight > 0.07) { //lower height of liquid
                    liquidHeight -= 0.02
                    liquidNode.geometry = SCNCylinder(radius: CGFloat(currentRadius), height: liquidHeight)
                    liquidNode.geometry?.materials.map({ material in
                        material.diffuse.contents = UIColor.red.withAlphaComponent(1)
                    })
                }
            }
        }
    }
}

public var counter = 0 // works as a logic switch so that pwrStatusControl() isnt read every second or else it would keep turning on every second :D

public func readPower(input: String) { //reading power switch from arduino
    if (counter == 0) {
        if (input == "ON") { //if switch on, turn on lcd screen and make counter logic switch 1 so it doesnt turn it on multiple times
            pwrStatus = true
            pwrStatusControl()
            counter = 1
        }
    } else { // once switch is off, it turns off lcd screen and counter goes back to 0 to wait until switch is on again
        if (input == "OFF") {
            pwrStatus = false
            pwrStatusControl()
            counter = 0
        }
    }
}

public var recipeCounter = 0 //checks which parameter is being edited

var savedStatus = false //checks if a parameter is saved yet
var editorMode = false

//every few milliseconds read keypad data and go through the lcd screen logic to enter parameters and then spin the wafer.

public func readPad(input: String) {
    if (input == "A") { //A pressed enters recipe editor and is used to toggle through each parameter
        editorMode = true
        homescreenStatus = false //once in editor mode, not in home screen
        savedStatus = false
        recipeCounter += 1
        if (recipeCounter == 5) { //loop back to rpm1 once u go through all the parameters
            recipeCounter = 1
        }
        text2.string = ""
        if (recipeCounter == 1) { //RPM1
            text2.string = "\(Int(rpm1))"
        }
        if (recipeCounter == 2) { //TIME1
            text2.string = "\(Int(time1))"
        }
        if (recipeCounter == 3) { //RPM2
            text2.string = "\(Int(rpm2))"
        }
        if (recipeCounter == 4) { //TIME2
            text2.string = "\(Int(time2))"
        }
    }
    if (input == "C") { //Toggle vacuum, make sure it's only able to turn on when wafer is placed on wafer, thus when centerStage > 0
        if (homescreenStatus) {
            if (vacuumState == false) {
                print(centerStage)
                if (centerStage != 0) {
                    vacuumState.toggle()
                    text2.string = "VACUUM: ON"
                    currentCenterStage = centerStage
                }
            } else {
                vacuumState.toggle()
                text2.string = "VACUUM: OFF"
            }
        }
    }
    if (recipeCounter == 1) { //Edit RPM1 value
        text.string = "Enter Stage 1 RPM: "
        if (input != "A" && input != "*" && input != "#" && input != "B") {
            if (text2.string as! String == "0") {
                text2.string = ""
            }
            if (savedStatus) {
                text2.string = "\(Int(rpm1))"
                savedStatus.toggle()
            }
            text2.string = text2.string as! String + input //add input to text2 string
        }
        if (input == "*") { //delete character
            text2.string = (text2.string as! String).dropLast()
        }
        if (input == "#") { //save number, will catch error if inputted a letter
            concatenatedInput = text2.string as! String//convert text2 string into this variable and turn it into a double below
            if let rpmTest = Double(concatenatedInput) {
                rpm1 = rpmTest
                concatenatedInput = ""
                print("RPM for stage 1 is: \(rpm1)")
                text2.string = text2.string as! String + " -- Saved"
                savedStatus = true
            } else {
                text.string = "Invalid Input (Stage 1 RPM):"
                concatenatedInput = ""
                text2.string = ""
            }
        }
    }
    if (recipeCounter == 2) {//all the rest are the same as above
        text.string = "Enter Stage 1 Time: "
        if (input != "A" && input != "*" && input != "#" && input != "B") {
            if (text2.string as! String == "0") {
                text2.string = ""
            }
            if (savedStatus) {
                text2.string = "\(Int(time1))"
                savedStatus.toggle()
            }
            text2.string = text2.string as! String + input
        }
        if (input == "*") {
            text2.string = (text2.string as! String).dropLast()
        }
        if (input == "#") {
            concatenatedInput = text2.string as! String
            if let timeTest = Double(concatenatedInput) {
                time1 = timeTest
                timeDuration1 = timeTest
                concatenatedInput = ""
                print("Time for stage 1 is: \(time1)")
                text2.string = text2.string as! String + " -- Saved"
                savedStatus = true
            } else {
                text.string = "Invalid Input (Stage 1 Time):"
                concatenatedInput = ""
                text2.string = ""
            }
        }
    }
    if (recipeCounter == 3) {
        text.string = "Enter Stage 2 RPM"
        if (input != "A" && input != "*" && input != "#" && input != "B") {
            if (text2.string as! String == "0") {
                text2.string = ""
            }
            if (savedStatus) {
                text2.string = "\(Int(rpm2))"
                savedStatus.toggle()
            }
            text2.string = text2.string as! String + input
        }
        if (input == "*") {
            text2.string = (text2.string as! String).dropLast()
        }
        if (input == "#") {
            concatenatedInput = text2.string as! String
            if let rpmTest = Double(concatenatedInput) {
                rpm2 = rpmTest
                concatenatedInput = ""
                print("RPM for stage 2 is: \(rpm2)")
                text2.string = text2.string as! String + " -- Saved"
                savedStatus = true
            } else {
                text.string = "Invalid Input (Stage 2 RPM):"
                concatenatedInput = ""
                text2.string = ""
            }
        }
    }
    if (recipeCounter == 4) {
        text.string = "Enter Stage 2 Time: "
        if (input != "A" && input != "*" && input != "#" && input != "B") {
            if (text2.string as! String == "0") {
                text2.string = ""
            }
            if (savedStatus) {
                text2.string = "\(Int(time2))"
                savedStatus.toggle()
            }
            text2.string = text2.string as! String + input
        }
        if (input == "*") {
            text2.string = (text2.string as! String).dropLast()
        }
        if (input == "#") {
            concatenatedInput = text2.string as! String
            if let timeTest = Double(concatenatedInput) {
                time2 = timeTest
                timeDuration2 = timeTest
                concatenatedInput = ""
                text2.string = text2.string as! String + " -- Saved"
                savedStatus = true
            } else {
                text.string = "Invalid Input (Stage 2 Time):"
                concatenatedInput = ""
                text2.string = ""
            }
        }
    }
    if (input == "B") { //"save data" and go back to home screen
        if (!homescreenStatus) {
            editorMode = false
            savedStatus = false
            text.string = "Saving Data."
            text2.string = ""
            print("Time for stage 2 is: \(time2)")//Debugging to make sure time variables are right
            print("stage 1 -- rpm: \(rpm1), time: \(time1)")
            print("stage 2 -- rpm: \(rpm2), time: \(time2)")
                
            let delay : Double = 1.5 //delay time in seconds
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                text.string = "Saving Data.."
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                    text.string = "Saving Data..."
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                        text.string = "Press 'A' To Edit Recipe"
                        if (vacuumState) {
                            text2.string = "VACUUM: ON"
                        } else {
                            text2.string = "VACUUM: OFF"
                        }
                    }
                }
            }
            homescreenStatus = true
            recipeCounter = 0
        }
    }
    if (input == "D") { //spin wafer if vacuum is on and rpm values above 0
        if (vacuumState && (rpm1 > 0) && (rpm2 > 0) && (time1 > 0) && (time2 > 0)) {
            spinningStatus.toggle()
            if (spinningStatus && homescreenStatus) { //spin if spinningStatus is true and on homescreen
                homescreenStatus = false
                convertRPMStage1()
            } else if (editorMode == false) { //if spinning is false, and not editing recipe then cancel spin and go back to homescreen
                homescreenStatus = true
                spinningStatus = false
                timer1?.invalidate()
                timer2?.invalidate()
                waferNode?.removeAllAnimations()
                text.string = "Spinning Cancelled"
                text2.string = "Home Screen Loading."
                let delay : Double = 0.5 //delay time in seconds
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                    text2.string = "Home Screen Loading.."
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                        text2.string = "Home Screen Loading..."
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                            text.string = "Press 'A' To Edit Recipe"
                            if (vacuumState) {
                                text2.string = "VACUUM: ON"
                            } else {
                                text2.string = "VACUUM: OFF"
                            }
                            recipeCounter = 0
                        }
                    }
                }
            }
        }
    }
}

private func convertRPMStage1() { //spin stage 1
    text2.string = "RPM: \(rpm1), Time: \(String(describing: Int(timeDuration1!)))"
    //wobble wafer by off centering it from center based on centerStage accuracy
    if (centerStage == 1) {
        waferNode?.pivot = SCNMatrix4MakeTranslation(-2, 0, 0)
    } else if (centerStage == 2) {
        waferNode?.pivot = SCNMatrix4MakeTranslation(-1, 0, 0)
    } else if (centerStage == 3) {
        waferNode?.pivot = SCNMatrix4MakeTranslation(-0.5, 0, 0)
    } else {
        waferNode?.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
    }
    //spin wafer -2pi (radians) for rpm at time with a little bit of math
    let spin = CABasicAnimation(keyPath: "rotation")
    // Use from-to to explicitly make a full rotation around z
    spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
    spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat(-2 * Double.pi)))) //y is 1 so it rotates on y-axis, w is angle, in this case 360 degrees or 2pi radians
    spin.duration = Double(1.0/rpm1) //duration for each spin is this so when multiplied by repeat count the total time adds up!
    print(Double(1.0/rpm1))
    spin.repeatCount = Float(time1*rpm1)
    print(Float(time1*rpm1))
    text.string = "Stage 1 Cycle:"
    waferNode?.addAnimation(spin, forKey: "spin around")
    spreadState = true//liquid should spread if poured onto wafer only
    var timeCopy = timeDuration1
    //timer using timeDuration1 to show how much time left in spin
    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
        if (spinningStatus == false) {
            timer.invalidate()
        } 
        if (timeCopy! > 0) {
            timeCopy! -= 1
            text2.string = "RPM: \(rpm1), Time: \(String(describing: Int(timeCopy!)))"
        }
        if (timeCopy! == 0) {
            text.string = "Stage 2 Cycle:"
            spinStage2 = true
            convertRPMStage2()
            timer.invalidate()
        }
    }
}

private func convertRPMStage2() { // spin stage 2, once timer done go back to home screen :D
    text2.string = "RPM: \(rpm2), Time: \(time2)"
    waferNode?.removeAllAnimations()
    let spin = CABasicAnimation(keyPath: "rotation")
        // Use from-to to explicitly make a full rotation around z
    spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
    spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat(-2 * Double.pi))))
    spin.duration = Double(1.0/rpm2)
    spin.repeatCount = Float(time2*rpm2)
    waferNode?.addAnimation(spin, forKey: "spin around part two")
    var timeCopy = timeDuration2
    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
        if (spinningStatus == false) {
            timer.invalidate()
        }
        if (timeCopy! > 0) {
            timeCopy! -= 1
            text2.string = "RPM: \(rpm2), Time: \(String(describing: Int(timeCopy!)))"
        } else {
            text2.string = "Stage 2 Complete."
            waferNode?.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
            timer.invalidate()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                text.string = "Spinning Complete!"
                text2.string = "Going Back."
                spinningStatus = false
                let delay : Double = 1.5 //delay time in seconds
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                    text2.string = "Going Back.."
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                        text2.string = "Going Back..."
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                            homescreenStatus = true
                            text.string = "Press 'A' To Edit Recipe"
                            if (vacuumState) {
                                text2.string = "VACUUM: ON"
                            } else {
                                text2.string = "VACUUM: OFF"
                            }
                            recipeCounter = 0
                        }
                    }
                }
            }
        }
    }
}

//run if power switch is turned off or on, either do a welcome message and go to home screen if switch is on, or if switch is off reset everything and turn off lcd screen.
private func pwrStatusControl() { //controls if powerswitch is on or off, how to turn on and off lcd screen and other settings in the set up
    
    hitNode?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: hitNode!))
    hitNode?.physicsBody?.isAffectedByGravity = false
    hitNode?.physicsBody?.categoryBitMask = BodyType.wafer.rawValue
    hitNode?.physicsBody?.contactTestBitMask = BodyType.spinnerInner.rawValue | BodyType.spinnerMiddle.rawValue | BodyType.spinnerOuter.rawValue //bring back hitNode nd reset it
    
    if (pwrStatus) { //if switch on, say welcome, set up screenNode to light up
        spinStage2 = false
        text.string = "Welcome!"
        text2.string = "--"
        screenNode?.geometry?.materials.map({ material in
            material.diffuse.contents = UIColor(red: 12.0/255.0, green: 12.0/255.0, blue: 110.0/255.0, alpha: 255.0)
        })
        text.font = UIFont(name: "Helvetica", size: 6.0)
        text2.font = UIFont(name: "Helvetica", size: 6.0)

        textNode.geometry = text
        textNode2.geometry = text2
        screenNode?.addChildNode(textNode)
        screenNode?.addChildNode(textNode2)
        
        //position textNodes so that they appear right on top of screen and rotated so facing up
        
        screenNode?.childNodes[0].pivot = SCNMatrix4MakeTranslation(-2, 10, -0.85)
        let roteAction = SCNAction.rotate(by: -(.pi/2), around: SCNVector3(1,0,0), duration: 0)
        screenNode?.childNodes[0].runAction(roteAction)
        
        screenNode?.childNodes[1].pivot = SCNMatrix4MakeTranslation(-2, 25, -0.85)
        screenNode?.childNodes[1].runAction(roteAction)
        
        let delay : Double = 2.0 //delay time in seconds
        let time = DispatchTime.now() + delay
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) { //go to homescreen
            homescreenStatus = true
            text.string = "Press 'A' to Edit Recipe"
            if (vacuumState) {
                text2.string = "VACUUM: ON"
            } else {
                text2.string = "VACUUM: OFF"
            }
        }
    } else {  // if power switch is off
        waferNode?.removeAllAnimations()
        timer1?.invalidate()//turn off timers
        timer2?.invalidate()
        spinningStatus = false
        screenNode?.geometry?.materials.map({ material in
            material.diffuse.contents = UIColor(red: 210.0/255.0, green: 215.0/255.0, blue: 211.0/255.0, alpha: 255.0/255.0)
        }) // make screen dark
        let reverseRoteAction = SCNAction.rotate(by: (.pi/2), around: SCNVector3(1,0,0), duration: 0)
        screenNode?.childNodes[1].runAction(reverseRoteAction)
        screenNode?.childNodes[0].runAction(reverseRoteAction)
        screenNode?.childNodes[1].removeFromParentNode()
        screenNode?.childNodes[0].removeFromParentNode() // remove text from screen and revert text back to original location since when u remove it it goes back to same location
        text.string = ""
        text2.string = ""
        spinStage2 = false
        centerStage = 0
        waferNode?.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
        spreadState = false
    }
}
