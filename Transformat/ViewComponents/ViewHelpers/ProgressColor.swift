//
//   Created by QIU DU on 13/5/22
//
//   Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

struct ProgressColor {
    
    static func color(_ progress: CGFloat) -> NSColor {
        let red = NSColor.red.redComponent * ( 1 - progress )
        let green = NSColor.green.greenComponent * progress
        let color = NSColor(calibratedRed: red, green: green, blue: .zero, alpha: 1)
        return color
    }
}
