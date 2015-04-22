//
//  MyApplication.swift
//  PocketCast
//
//  Created by Morten Just Petersen on 4/14/15.
//  Copyright (c) 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa

@objc(MyApplication)
class MyApplication: NSApplication {
    
    override init() {
        println("overriden, boom")
        super.init()
    }

    override func sendEvent(theEvent: NSEvent) {
        var overridden=false
        
        if (theEvent.type == NSEventType.SystemDefined) {
            
            if theEvent.subtype.rawValue == 8 {
                
                switch theEvent.data1 {
                case 1379072:
                    NSNotificationCenter.defaultCenter().postNotificationName("pocketEvent", object: self, userInfo:["action":"skip"])
                    overridden = true
                    
                case 1444608:
                    NSNotificationCenter.defaultCenter().postNotificationName("pocketEvent", object: self, userInfo:["action":"playPause"])
                    overridden = true
                default:
                    println("Something else")
                }
            }
            
        }

        if !overridden {
            super.sendEvent(theEvent)
            }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}