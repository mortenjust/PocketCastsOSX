//
//  AppDelegate.swift
//  PocketCast
//
//  Created by Morten Just Petersen on 4/14/15.
//  Copyright (c) 2015 Morten Just Petersen. All rights reserved.
//  Forked by Vasil Pendavinji on 11/6/2016
//

import Cocoa
import WebKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebPolicyDelegate, WebResourceLoadDelegate {

    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var reloadButton: NSButton!
    
    var loadedItems = 0
    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)

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

        reloadButton.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.gotNotification(_:)), name: NSNotification.Name(rawValue: "pocketEvent"), object: nil)

        webView.mainFrameURL = "https://play.pocketcasts.com/"
        webView.policyDelegate = self
        webView.resourceLoadDelegate = self
        webView.wantsLayer = true

        mediaKeyTap = SPMediaKeyTap(delegate: self)
        if (SPMediaKeyTap.usesGlobalMediaKeyTap()) {
            mediaKeyTap!.startWatchingMediaKeys()
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
            button.image?.isTemplate = false
        }
        
        let statusBarMenu = NSMenu()
        statusBarMenu.addItem(withTitle: "Show", action: #selector(statusBarShow(_:)), keyEquivalent: "")
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(withTitle: "Play / Pause", action: #selector(statusBarPlayPause(_:)), keyEquivalent: "")
        statusBarMenu.addItem(withTitle: "Forward 45 Seconds", action: #selector(statusBarForward(_:)), keyEquivalent: "")
        statusBarMenu.addItem(withTitle: "Back 10 Seconds", action: #selector(statusBarBack(_:)), keyEquivalent: "")
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(withTitle: "Quit", action: #selector(statusBarQuit(_:)), keyEquivalent: "")
        statusItem.menu = statusBarMenu
    }
    
    @IBAction func newWindow(_ sender: NSMenuItem) {
        window.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func reloadPage(_ sender: AnyObject) {
        webView.reload(sender)
    }
    
    @IBAction func reloadButtonPressed(_ sender: Any) {
        webView.reload(sender)
    }
    
    func statusBarShow(_ sender: AnyObject) {
        print("clicked show")
        window.makeKeyAndOrderFront(sender)
    }
    
    //# TODO: add hide?
    
    func statusBarPlayPause(_ sender: AnyObject) {
        print("clicked play / pause")
        playPause()
    }
    
    func statusBarForward(_ sender: AnyObject) {
        print("clicked forward")
        skipForward()
    }
    
    func statusBarBack(_ sender: AnyObject) {
        print("clicked back")
        skipBack()
    }
    
    func statusBarQuit(_ sender: AnyObject) {
        print("clicked quit")
        NSApplication.shared().terminate(self)
    }
    
    func webView(_ webView: WebView!, decidePolicyForNewWindowAction actionInformation: [AnyHashable: Any]!, request: URLRequest!, newFrameName frameName: String!, decisionListener listener: WebPolicyDecisionListener!) {
        NSWorkspace.shared().open(request.url!)
    }
    
    func webView(_: WebView!, resource: Any!, didFinishLoadingFrom: WebDataSource!) {
        if let url = didFinishLoadingFrom.request.url, url.absoluteString == "https://play.pocketcasts.com/web/podcasts/index#/podcasts" {
            reloadButton.isHidden = false
        }
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
    
    func playPause() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo: ["action":"playPause"])
    }
    
    func skipForward() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo: ["action":"skipForward"])
    }
    
    func skipBack() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo: ["action":"skipBack"])
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
                    skipForward()

                case Int(NX_KEYTYPE_REWIND):
                    skipBack()
                default:
                    break
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

