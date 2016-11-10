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
        UserDefaults.standard.register(
            defaults: [kMediaKeyUsingBundleIdentifiersDefaultsKey : SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()])
    }


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let window = NSApplication.shared().windows.first!
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: CGFloat(0xf4)/CGFloat(0xff), green: CGFloat(0x43)/CGFloat(0xff), blue: CGFloat(0x36)/CGFloat(0xff), alpha: 1.0)
        
        // let repFileName = window.representedFilename
        let repFileName = "mainWindow"
        print("repfile: \(repFileName)")
        
        
        window.setFrameUsingName(repFileName)
        window.setFrameAutosaveName(repFileName)
        window.windowController?.shouldCascadeWindows = false
        
        window.isReleasedWhenClosed = false

        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.gotNotification(_:)), name: NSNotification.Name(rawValue: "pocketEvent"), object: nil)

        webView.mainFrameURL = "https://play.pocketcasts.com/"
        webView.policyDelegate = self
        webView.wantsLayer = true

        mediaKeyTap = SPMediaKeyTap(delegate: self)
        if (SPMediaKeyTap.usesGlobalMediaKeyTap()) {
            mediaKeyTap!.startWatchingMediaKeys()
        }
    }
    
    @IBAction func newWindow(_ sender: NSMenuItem) {
        window.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func reloadPage(_ sender: AnyObject) {
        webView.reload(sender)
    }
    
    func webView(_ webView: WebView!, decidePolicyForNewWindowAction actionInformation: [AnyHashable: Any]!, request: URLRequest!, newFrameName frameName: String!, decisionListener listener: WebPolicyDecisionListener!) {
        NSWorkspace.shared().open(request.url!)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false;
    }
    
    func applicationShouldHandleReopen(_ _sender: NSApplication,
                                         hasVisibleWindows flag: Bool) -> Bool{
        window.setIsVisible(true)
        return true
    }

    func gotNotification(_ notification : Notification){
		if let userInfo = notification.userInfo as? Dictionary<String,String> {
			if let action = userInfo["action"] {
				print("Got Notification \(action)")
				let angularMediaPlayerSelector = "angular.element(document).injector().get('mediaPlayer')"
				
				switch(action) {
					case "playPause":
						webView.stringByEvaluatingJavaScript(
							from: "\(angularMediaPlayerSelector).playPause()")
					
					case "skipForward":
						webView.stringByEvaluatingJavaScript(
							from: "\(angularMediaPlayerSelector).jumpForward()")
					
					case "skipBack":
						webView.stringByEvaluatingJavaScript(
							from: "\(angularMediaPlayerSelector).jumpBack()")
					
					default:
						break
				}
			}
		}
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "Play Control")
        let item = NSMenuItem(title: "Play/Pause", action: #selector(AppDelegate.playPause), keyEquivalent: "P")
        menu.addItem(item)
        return menu
    }
    
    func playPause(){
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "pocketEvent"), object:NSApp, userInfo:["action":"playPause"])
    }
    
    override func mediaKeyTap(_ mediaKeyTap : SPMediaKeyTap?, receivedMediaKeyEvent event : NSEvent) {

        let keyCode = Int((event.data1 & 0xFFFF0000) >> 16);
        let keyFlags = (event.data1 & 0x0000FFFF);
        let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;

        if (keyIsPressed) {
            switch (keyCode) {
                case Int(NX_KEYTYPE_PLAY):
                    playPause()

                case Int(NX_KEYTYPE_FAST):
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo:["action":"skipForward"])

                case Int(NX_KEYTYPE_REWIND):
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo:["action":"skipBack"])

                default:
                    break
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

