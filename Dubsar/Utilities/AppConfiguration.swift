/*
Dubsar Dictionary Project
Copyright (C) 2010-14 Jimmy Dee

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

import UIKit

struct AppConfiguration {

    static let fontFamilyKey = "DubsarFontFamily"

    static func preferredFontDescriptorWithTextStyle(style: String!, italic: Bool=false) -> UIFontDescriptor! {
        let fontDesc = UIFontDescriptor.preferredFontDescriptorWithTextStyle(style) // just for the pointSize

        var name = "Arial"

        var object: AnyObject? = NSUserDefaults.standardUserDefaults().valueForKey(fontFamilyKey)
        if object {
            if var value = object as? String {
                // NSLog("%@ = %@", fontFamilyKey, value)

                name = value
            }
            else {
                NSLog("%@ setting is not a string", fontFamilyKey)
            }
        }

        if style == UIFontTextStyleHeadline {
            name = "\(name) Bold"
        }
        if italic {
            name = "\(name) Italic"
        }

        return UIFontDescriptor(name: name, size: fontDesc.pointSize)
    }

    static func preferredFontForTextStyle(style: String!, italic: Bool=false) -> UIFont! {
        let fontDesc = preferredFontDescriptorWithTextStyle(style, italic: italic)
        return UIFont(descriptor: fontDesc, size: 0.0)
    }

    static let backgroundColor = UIColor.whiteColor()
    static let alternateBackgroundColor = UIColor.lightGrayColor()
    static let highlightColor = UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
    static let alternateHighlightColor = UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0)

}
