//
//  WebViewWithKeyboard.swift
//  PocketCast
//
//  Created by Adam Aviner on 06/04/2016.
//  Copyright © 2016 Morten Just Petersen. All rights reserved.
//

import Foundation
import WebKit

class WebViewWithKeyboardEvents: WebView {
    override func keyDown(theEvent: NSEvent) {
        if let char = theEvent.characters {
            switch char {
            case "c":
                self.copy(nil)
            case "x":
                self.cut(nil)
            case "a":
                self.selectAll(nil)
            case "v":
                self.paste(nil)
            default:
                return
            }
        }
    }
}