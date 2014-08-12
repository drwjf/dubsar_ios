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

import DubsarModels
import UIKit

class OpenSynsetTableViewCell: SynsetTableViewCell {
    var insertHeightLimit : CGFloat

    class var openIdentifier : String {
        get {
            return "opensynset"
    }
    }

    init(synset: DubsarModelsSynset!, frame: CGRect, maxHeightOfAdditions: CGFloat) {
        insertHeightLimit = maxHeightOfAdditions
        super.init(synset: synset, frame: frame, identifier: OpenSynsetTableViewCell.openIdentifier)
    }

    override func rebuild() {
        super.rebuild()

        backgroundColor = backgroundLabel.backgroundColor

        var y = bounds.size.height

        DMTRACE("Height of synset header \(y)")

        if !synset.complete {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
            backgroundLabel.addSubview(spinner)
            spinner.startAnimating()
            spinner.frame = CGRectMake(2.0, y + 2.0, 40.0, 40.0)

            frame.size.height += 44
            view!.frame.size.height = bounds.size.height

            return
        }

        let accessoryWidth = SynsetTableViewCell.accessoryWidth

        let sampleView = SynsetSampleView(synset: synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, bounds.size.height), preview: true)
        backgroundLabel.addSubview(sampleView)
        sampleView.layoutSubviews()

        sampleView.backgroundColor = UIColor.clearColor()

        var available = insertHeightLimit
        if available > 0 {
            DMTRACE("available = \(available)")
            if sampleView.bounds.size.height > available {
                DMTRACE("sampleView size of \(sampleView.bounds.size.height) truncated")
                sampleView.frame.size.height = available
            }
            available -= sampleView.bounds.size.height
            DMTRACE("available reduced to \(available)")
            if available <= 0 {
                // used up all our space. don't insert the pointer view
                frame.size.height += sampleView.bounds.size.height
                view!.frame.size.height = bounds.size.height
                DMTRACE("No pointer view. sample view height is \(sampleView.bounds.size.height). frame height is now \(bounds.size.height)")
                addGradientToBottomOfView(view)
                return
            }
        }

        frame.size.height += sampleView.bounds.size.height
        view!.frame.size.height = bounds.size.height

        if synset.numberOfSections == 0 {
            return
        }

        y = bounds.size.height

        DMTRACE("sample view is \(sampleView.bounds.size.width) x \(sampleView.bounds.size.height). frame height is now \(frame.size.height) (remaining insertHeightLimit: \(available))")

        let pointerView = SynsetPointerView(synset: synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, bounds.size.height), preview: true)
        pointerView.scrollViewTop = 0
        pointerView.scrollViewBottom = available
        pointerView.backgroundColor = UIColor.clearColor()
        backgroundLabel.addSubview(pointerView)
        pointerView.layoutSubviews()

        var truncated = false

        if available > 0 {
            DMTRACE("available = \(available)")
            if pointerView.bounds.size.height > available {
                DMTRACE("pointerView size of \(pointerView.bounds.size.height) truncated")
                pointerView.frame.size.height = available
                truncated = true
            }
        }

        frame.size.height += pointerView.bounds.size.height
        view!.frame.size.height = bounds.size.height

        DMTRACE("pointer view is \(pointerView.bounds.size.width) x \(pointerView.bounds.size.height). frame height is now \(frame.size.height)")

        if truncated {
            addGradientToBottomOfView(view)
        }

        DMTRACE("Actual height of open synset cell \(bounds.size.height)")
    }

    private func addGradientToBottomOfView(aView: UIView!) {
        let topColor = UIColor.clearColor()
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        topColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // let bottomColor = UIColor(hue: hue, saturation: saturation, brightness: brightness > 0.5 ? 0.3 * brightness : 2.0 * brightness, alpha: alpha)
        let bottomColor = UIColor.blackColor()

        let gradientHeight: CGFloat = 8
        let gradientView = GradientView(frame: CGRectMake(0, aView.bounds.size.height - gradientHeight, aView.bounds.width, gradientHeight), firstColor: topColor, secondColor: bottomColor, startPoint: CGPointMake(0, 0), endPoint: CGPointMake(0, gradientHeight))
        gradientView.opaque = false
        gradientView.alpha = 0.333
        gradientView.autoresizingMask = .FlexibleWidth | .FlexibleTopMargin
        
        DMTRACE("Added gradient at \(gradientView.frame.origin.y)")
        aView.addSubview(gradientView)
    }
}
