//
//  AppDelegate.swift
//  PocketCast
//
//  Created by Morten Just Petersen on 4/14/15.
//  Copyright (c) 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa
import WebKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebPolicyDelegate {

    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var window: NSWindow!

    var mediaKeyTap: SPMediaKeyTap?

    override init() {
        // Register defaults for the whitelist of apps that want to use media keys
        NSUserDefaults.standardUserDefaults().registerDefaults(
            [kMediaKeyUsingBundleIdentifiersDefaultsKey : SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()])
    }


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let window = NSApplication.sharedApplication().windows.first!
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.movableByWindowBackground = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gotNotification:", name: "pocketEvent", object: nil)

        webView.mainFrameURL = "https://play.pocketcasts.com/"
        webView.policyDelegate = self

        mediaKeyTap = SPMediaKeyTap(delegate: self)
        if (SPMediaKeyTap.usesGlobalMediaKeyTap()) {
            mediaKeyTap!.startWatchingMediaKeys()
        }
    }
    
    func webView(webView: WebView!, decidePolicyForNewWindowAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, newFrameName frameName: String!, decisionListener listener: WebPolicyDecisionListener!) {
        NSWorkspace.sharedWorkspace().openURL(request.URL!)
    }

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true;
    }

    func gotNotification(notification : NSNotification){
		if let userInfo = notification.userInfo as? Dictionary<String,String> {
			if let action = userInfo["action"] {
				print("Got Notification \(action)")
				let angularMediaPlayerSelector = "angular.element(document).injector().get('mediaPlayer')"
				
				switch(action) {
					case "playPause":
						webView.stringByEvaluatingJavaScriptFromString(
							"\(angularMediaPlayerSelector).playPause()")
					
					case "skipForward":
						webView.stringByEvaluatingJavaScriptFromString(
							"\(angularMediaPlayerSelector).jumpForward()")
					
					case "skipBack":
						webView.stringByEvaluatingJavaScriptFromString(
							"\(angularMediaPlayerSelector).jumpBack()")
					
					default:
						break
				}
			}
		}
    }

    func applicationDockMenu(sender: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "Play Control")
        let item = NSMenuItem(title: "Play/Pause", action: "playPause", keyEquivalent: "P")
        menu.addItem(item)
        return menu
    }
    
    func playPause(){
        NSNotificationCenter.defaultCenter().postNotificationName(
            "pocketEvent", object:NSApp, userInfo:["action":"playPause"])
    }
    
    override func mediaKeyTap(mediaKeyTap : SPMediaKeyTap?, receivedMediaKeyEvent event : NSEvent) {

        let keyCode = Int((event.data1 & 0xFFFF0000) >> 16);
        let keyFlags = (event.data1 & 0x0000FFFF);
        let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;

        if (keyIsPressed) {
            switch (keyCode) {
                case Int(NX_KEYTYPE_PLAY):
                    playPause()

                case Int(NX_KEYTYPE_FAST):
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        "pocketEvent", object: NSApp, userInfo:["action":"skipForward"])

                case Int(NX_KEYTYPE_REWIND):
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        "pocketEvent", object: NSApp, userInfo:["action":"skipBack"])

                default:
                    break
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

