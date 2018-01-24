//
//  SKJoystick.swift
//  SKJoystick
//                                                         \|/
//                                                         @ @
//  +--------------------------------------------------oOO-(_)-OOo---+
//  Created by Alessandro Ornano on 24/01/2018.
//  Copyright © 2018 Alessandro Ornano. All rights reserved.
//

import Foundation
import SpriteKit

protocol SKJoystickDelegate: class {
    func joystickUpdatedDirection(sender : AnyObject)
    func joystickReleased(sender : AnyObject)
}
enum Sense: Int {
    case UP = 0
    case UP_RIGHT = 1
    case RIGHT = 2
    case DOWN_RIGHT = 3
    case DOWN = 4
    case DOWN_LEFT = 5
    case LEFT = 6
    case UP_LEFT = 7
    case RELEASED = 8
}
class SKJoystick : SKSpriteNode {
    let numberOfStickLayers = 20
    let numberOfDefaultLayers = 6
    var maxDistance:Float = 50.0 // 50-80
    let stiffness = 30.0 //recomended between 1.0 - 99.0, default is 30.0
    let deadZone = 24.0
    let joystickNormalizedCenter = CGPoint(x:0.5,y:0.5)
    let stickName = "stick"
    var directionPoint: CGPoint!
    weak var delegate:SKJoystickDelegate?
    var knob: SKSpriteNode!
    var lastTouch: SKSpriteNode!
    var direction: Sense = Sense.RELEASED
    private var isTouched:Bool = false
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK: - Joystick init methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    override init(texture: SKTexture?, color: SKColor = .clear, size: CGSize = CGSize(width:200.0,height:200.0)) {
        super.init(texture: texture, color: color, size: size)
        // Setting up rubber base sprites
        for i in 1..<numberOfDefaultLayers {
            let fileName = NSString(format: "layer%d.png",i)
            let layerTexture = SKTexture(imageNamed: fileName as String)
            let layer = SKSpriteNode(texture:layerTexture,size: getScaledSize(self,layerTexture))
            layer.zPosition = CGFloat(i)
            self.addChild(layer)
            layer.position = joystickNormalizedCenter
        }
        // Setting up metal stick sprites
        for i in numberOfDefaultLayers..<(numberOfStickLayers + numberOfDefaultLayers) {
            let stickTexture = SKTexture(imageNamed: "stick.png")
            let stickLayer = SKSpriteNode(texture:stickTexture,size: getScaledSize(self,stickTexture))
            self.addChild(stickLayer)
            stickLayer.zPosition = CGFloat(numberOfDefaultLayers+i)
            var stickScale:CGFloat = 0.98
            let scaleSubtraction = CGFloat(((Float(numberOfStickLayers) - Float(i - numberOfDefaultLayers))/Float(numberOfStickLayers)))
            stickScale -= (scaleSubtraction * 0.5)
            stickLayer.setScale(stickScale)
            stickLayer.position = joystickNormalizedCenter
            stickLayer.name = stickName
        }
        let knobTexture = SKTexture(imageNamed: "blueKnob.png")
        knob = SKSpriteNode(texture:knobTexture,size: getScaledSize(self,knobTexture))
        knob.zPosition = 100
        self.addChild(knob)
        knob.position = joystickNormalizedCenter
        self.isUserInteractionEnabled = true
    }
    
    convenience init(texture: SKTexture?, color: SKColor = .clear, size: CGSize = CGSize(width:200.0,height:200.0),knob:String! = "blueKnob.png") {
        self.init(texture: texture, color: color, size: size)
        let knobTexture = SKTexture(imageNamed: knob)
        self.knob.texture = knobTexture
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK: - Calculation
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    // Convert an entity size following percentage to node size
    func getScaledSize(_ node:AnyObject,_ texture:SKTexture) -> CGSize {
        var newSize = texture.size()
        let newWidth = (node.size.width*newSize.width)/200.0
        let newHeight = (node.size.height * newSize.height)/200.0
        newSize = CGSize(width: newWidth,height: newHeight)
        return newSize
    }
    func distanceBetweenPoints(_ first:CGPoint,_ second:CGPoint)->CGFloat {
        return CGFloat(hypotf(Float(second.x) - Float(first.x), Float(second.y - first.y)))
    }
    ///Returns the input value clamped to the lower and upper limits.
    func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
        return min(max(value, lower), upper)
    }
    func clampf(_ value:Float,_ min_inclusive:Float,_ max_inclusive:Float)->Float {
        let result : Float = clamp(value: value, lower: min_inclusive, upper: max_inclusive)
        return result
    }
    func CGPointMult(_ v:CGPoint, _ s:CGFloat)->CGPoint
    {
        return CGPoint(x:v.x*s, y:v.y*s)
    }
    func CGPointAdd(_ v1:CGPoint, _ v2:CGPoint)->CGPoint
    {
        return CGPoint(x:v1.x + v2.x, y:v1.y + v2.y)
    }
    func angleBetween(_ startPoint:CGPoint,_ endPoint:CGPoint)->CGFloat {
        let originPoint = CGPoint(x:endPoint.x - startPoint.x,y:endPoint.y - startPoint.y)
        let bearingRadians = atan2f(Float(originPoint.y), Float(originPoint.x))
        var bearingDegrees = bearingRadians * (180.0 / Float(Double.pi))
        bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees))
        return CGFloat(bearingDegrees)
    }
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK: - Touch methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        isTouched = true
        self.removeAllActions()
        for layer in self.children {
            layer.removeAllActions()
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouched = true
        let touch = touches.first
        var distance = distanceBetweenPoints((touch?.location(in: self.parent!))!,self.position)
        distance =  CGFloat(clampf(Float(distance), 0, maxDistance))
        let angle = self.angleBetween(self.position, (touch?.location(in: self.parent!))!)
        let vx = cos(angle * CGFloat(Double.pi) / 180) * (distance * 1.5)
        let vy = sin(angle * CGFloat(Double.pi) / 180) * (distance * 1.5)
        self.directionPoint = CGPoint(x:vx/distance,y:vy/distance)
        let darkness = (127 * (vy/CGFloat(maxDistance)))
        var i=0
        let count = self.children.count
        for layer in self.children {
            let addition = CGPointMult(CGPoint(x:vx,y:vy), CGFloat(Float(i)/Float(count)))
            layer.position = CGPointAdd(joystickNormalizedCenter, addition)
            if layer.name == stickName {
                let l = layer as! SKSpriteNode
                l.color = SKColor(white: 0.8 - (( darkness / 200.0) * CGFloat(Float(i)/Float(count))), alpha:1.0)
            }
            i = i+1
        }
        switch Double(angle) {
        case 90.0-deadZone...90.0+deadZone:
            direction = .UP
        case 270.0-deadZone...270.0+deadZone:
            direction = .DOWN
        case 180.0-deadZone...180.0+deadZone:
            direction = .LEFT
        case 360.0-deadZone...360.0:
            direction = .RIGHT
        case 0.0...deadZone:
            direction = .RIGHT
        case 135.0-deadZone...135.0+deadZone:
            direction = .UP_LEFT
        case 45.0-deadZone...45.0+deadZone:
            direction = .UP_RIGHT
        case 225.0-deadZone...225.0+deadZone:
            direction = .DOWN_LEFT
        case 315.0-deadZone...315.0+deadZone:
            direction = .DOWN_RIGHT
        default:
            break
        }
        updateStatus()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouched = false
        self.removeAllActions()
        for layer in self.children {
            layer.removeAllActions()
        }
        let duration = 1.0 - (stiffness/100.0)
        for sprite in self.children {
            let resetAction = SKEase.moveToWithNode(sprite, easeFunction: CurveType.curveTypeElastic, easeType: EaseType.easeTypeOut, time: duration, to: CGPoint(x:joystickNormalizedCenter.x, y:joystickNormalizedCenter.y))
            sprite.run(resetAction)
        }
        self.directionPoint = CGPoint.zero
        direction = .RELEASED
        updateStatus()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
    func updateStatus() {
        //print("updateStatus")
        if self.delegate != nil {
            if isTouched {
                if let joystickUpdatedDirection = self.delegate?.joystickUpdatedDirection {
                    joystickUpdatedDirection(self)
                }
            } else {
                if let joystickReleased = self.delegate?.joystickReleased{
                    joystickReleased(self)
                }
            }
        }
    }
}

