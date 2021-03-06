/*
Dubsar Dictionary Project
Copyright (C) 2010-15 Jimmy Dee

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

class NavButton: UIButton {
    override var frame: CGRect {
    didSet {
        refreshImages()
    }
    }

    init() {
        super.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        refreshImages()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func refreshImages() {
        let normalImage = NavButtonImage.imageWithSize(bounds.size, color: AppConfiguration.foregroundColor)
        let highlightedImage = NavButtonImage.imageWithSize(bounds.size, color: AppConfiguration.highlightedForegroundColor)
        let disabledImage = NavButtonImage.imageWithSize(bounds.size, color: AppConfiguration.alternateBackgroundColor)

        setImage(normalImage, forState: .Normal)
        setImage(highlightedImage, forState: .Highlighted)
        setImage(disabledImage, forState: .Disabled)
    }
}
