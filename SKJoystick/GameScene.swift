//
//  GameScene.swift
//  SKJoystick
//
//  Created by Alessandro Ornano on 24/01/2018.
//  Copyright © 2018 Alessandro Ornano. All rights reserved.
//

import SpriteKit
class GameScene: SKScene, SKJoystickDelegate {
    var joyStick : SKJoystick!
    var jumpBtn: SKSpriteNode!
    var fireBtn: SKSpriteNode!
    var duckBtn: SKSpriteNode!
    override func didMove(to view: SKView) {
        print("---")
        print("❊ \(type(of: self))")
        print("---")
        self.backgroundColor = .white
        // Show joystick
        let joySize = CGSize(width:300,height:300)
        joyStick = SKJoystick.init(texture: nil, color: .clear, size: joySize, knob:"blueKnob.png")
        self.addChild(joyStick)
        joyStick.zPosition = 1
        joyStick.alpha = 0.5
        
        joyStick.position = CGPoint(x:self.frame.width/7,y:self.frame.height/4)
        joyStick.isUserInteractionEnabled = true
        joyStick.delegate = self
        
        // Show buttons
        let jumpBtnUpTxt = SKTexture(imageNamed:"btn-up-green")
        self.jumpBtn = SKSpriteNode(texture:jumpBtnUpTxt, size: getSizeForPercentage(node: self, texture: jumpBtnUpTxt, perc: 15.0))
        self.jumpBtn.zPosition = 1
        self.jumpBtn.alpha = 0.80
        self.jumpBtn.name = "jumpBtn"
        self.addChild(jumpBtn)
        self.jumpBtn.position = CGPoint(x:self.frame.width/1.7, y:self.frame.height*0.15)
        let fireBtnUpTxt = SKTexture(imageNamed:"btn-up-red")
        self.fireBtn = SKSpriteNode(texture:fireBtnUpTxt, size: getSizeForPercentage(node: self, texture: fireBtnUpTxt, perc: 15.0))
        self.fireBtn.zPosition = 1
        self.fireBtn.alpha = 0.80
        self.fireBtn.name = "fireBtn"
        self.addChild(fireBtn)
        self.fireBtn.position = CGPoint(x:self.frame.width/1.15, y:self.frame.height*0.4)
        let duckBtnUpTxt = SKTexture(imageNamed:"btn-up-gold")
        self.duckBtn = SKSpriteNode(texture:duckBtnUpTxt, size: getSizeForPercentage(node: self, texture: duckBtnUpTxt, perc: 15.0))
        self.duckBtn.zPosition = 1
        self.duckBtn.alpha = 0.80
        self.duckBtn.name = "duckBtn"
        self.addChild(duckBtn)
        self.duckBtn.position = CGPoint(x:self.frame.width/1.3, y:self.frame.height*0.15)
    }
    
    // Convert an entity size following percentage to node size
    func getSizeForPercentage(node:AnyObject, texture:AnyObject, perc: CGFloat) -> CGSize {
        var newSize = CGSize.zero
        let newWidth = (node.size.width*perc)/100
        let newHeight = (newWidth * texture.size.height) / texture.size.width
        newSize = CGSize(width: newWidth,height: newHeight)
        return newSize
    }
    
    func pressBtn(btn:SKSpriteNode, color:String) {
        if btn.action(forKey: "\(String(describing: btn.name))Pressed") != nil {
            btn.removeAllActions()
            btn.texture = SKTexture(imageNamed:"btn-up-\(color)")
        } else {
            let scaleDownAction = SKAction.scale(to: 0.99, duration: 0.25)
            let origTxt = btn.texture
            let changeTxt = SKTexture(imageNamed:"btn-down-\(color)")
            let changeTxtAction = SKAction.run {
                btn.texture = changeTxt
            }
            let origTxtAction = SKAction.run {
                btn.texture = origTxt
            }
            let playSound = SKAction.playSoundFileNamed("tap.mp3", waitForCompletion: true)
            let scaleUpAction = SKAction.scale(to: 1, duration: 0.25 / 2)
            btn.run(playSound)
            btn.run(SKAction.sequence([changeTxtAction,scaleDownAction,scaleUpAction,origTxtAction]), withKey: "\(String(describing: btn.name))Pressed")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        //print(touchedNode)
        switch touchedNode.name {
        case "jumpBtn"?:
            print("You've press jumpBtn")
            pressBtn(btn: self.jumpBtn,color: "green")
        case "fireBtn"?:
            print("You've press fireBtn")
            pressBtn(btn: self.fireBtn,color: "red")
        case "duckBtn"?:
            print("You've press duckBtn")
            pressBtn(btn: self.duckBtn,color: "gold")
        default:break
        }
    }
    
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    //MARK:- SKJoystick delegate methods
    // #-#-#-#-#-#-#-#-#-#-#-#-#-#-#
    func joystickUpdatedDirection(sender _: AnyObject) {
        print("\(#function) - \(self.joyStick.direction)")
    }
    func joystickReleased(sender _: AnyObject) {
        print("\(#function)")
    }
}
