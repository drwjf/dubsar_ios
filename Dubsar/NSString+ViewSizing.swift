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

extension NSString {

    func sizeOfTextWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        if !font {
            return CGSizeZero
        }

        let context = NSStringDrawingContext()
        return boundingRectWithSize(constrainedSize, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font!], context: context).size
    }

    func sizeOfTextWithFont(font: UIFont?) -> CGSize {
        var size : CGSize = CGSizeZero
        if !font {
            return size
        }

        if respondsToSelector("sizeWithAttributes:") {
            // iOS 7+
            size = sizeWithAttributes([NSFontAttributeName: font!])
        }
        else if respondsToSelector("sizeWithFont:") {
            // iOS 6 - though not currently supported because of dynamic type issues
            // and as of Beta3, anything deprecated in iOS 7.0 is not available in Swift
            // size = sizeWithFont(font)
            // so when I care about iOS 6, should use Obj-C.
        }

        return size
    }
}
