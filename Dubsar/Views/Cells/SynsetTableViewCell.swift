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

class SynsetTableViewCell: UITableViewCell {

    // essentially public class constants
    class var identifier : String {
        get {
            return "synset"
    }
    }

    class var borderWidth : CGFloat {
        get {
            return 0
    }
    }

    class var margin : CGFloat {
        get {
            return 6
    }
    }

    // just some extra margin on the right to avoid getting clobbered by the accessory
    class var accessoryWidth : CGFloat {
        get {
            return 60
    }
    }

    class var labelLineHeight : CGFloat {
        get {
            return 21
    }
    }

    var synset : DubsarModelsSynset! {
    didSet {
        rebuild()
    }
    }

    var cellBackgroundColor : UIColor! = AppConfiguration.backgroundColor {
    didSet {
        rebuild()
    }
    }

    /*
    * The main thing this class does is build this view, which is added as a subview of
    * contentView. Each time rebuild() is called, this view is removed from the superview
    * if non-nil and reconstructed. Removing it from the superview is the only reason to
    * make this a property.
    */
    var view : UIView?
    var backgroundLabel : UIView!

    init(synset: DubsarModelsSynset!, frame: CGRect, identifier: String = SynsetTableViewCell.identifier) {
        self.synset = synset
        super.init(style: .Default, reuseIdentifier: identifier)

        self.frame = frame

        accessoryType = .DetailDisclosureButton
        clipsToBounds = true

        rebuild()
    }

    func rebuild() {
        let borderWidth = SynsetTableViewCell.borderWidth
        let margin = SynsetTableViewCell.margin

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let caption1Font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleCaption1)
        let subheadlineFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleSubheadline)

        let constrainedSize = CGSizeMake(frame.size.width-2*borderWidth-2*margin-SynsetTableViewCell.accessoryWidth, frame.size.height)
        let glossSize = synset.glossSizeWithConstrainedSize(constrainedSize, font: bodyFont)
        let synonymSize = synset.synonymSizeWithConstrainedSize(constrainedSize, font: caption1Font)

        bounds.size.height = synset.sizeOfCellWithConstrainedSize(constrainedSize, open:false).height

        view?.removeFromSuperview()

        view = UIView(frame: bounds)
        view!.backgroundColor = AppConfiguration.foregroundColor // for a border

        view!.autoresizingMask = nil

        contentView.addSubview(view)

        backgroundLabel = UIView(frame: CGRectMake(borderWidth, borderWidth, bounds.size.width-2*borderWidth, bounds.size.height-2*borderWidth))
        // backgroundLabel.clipsToBounds = true
        backgroundLabel.backgroundColor = selected ? AppConfiguration.highlightColor : cellBackgroundColor
        backgroundLabel.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        view!.addSubview(backgroundLabel)

        var lexnameText = "<\(synset.lexname)>"

        if synset.freqCnt > 0 {
            lexnameText = "\(lexnameText) freq. cnt.: \(synset.freqCnt)"
        }

        let lexnameLabel = UILabel(frame: CGRectMake(margin, margin, constrainedSize.width, SynsetTableViewCell.labelLineHeight))
        lexnameLabel.text = lexnameText
        lexnameLabel.font = subheadlineFont
        lexnameLabel.numberOfLines = 1
        lexnameLabel.textColor = AppConfiguration.foregroundColor
        backgroundLabel.addSubview(lexnameLabel)

        let textLabel = UILabel(frame: CGRectMake(margin, 2*margin + SynsetTableViewCell.labelLineHeight, constrainedSize.width, glossSize.height))
        textLabel.font = bodyFont
        textLabel.text = synset.gloss
        textLabel.lineBreakMode = .ByWordWrapping
        textLabel.numberOfLines = 0
        textLabel.textColor = AppConfiguration.foregroundColor
        backgroundLabel.addSubview(textLabel)

        if synset.senses.count > 0 {
            let synonymLabel = UILabel(frame: CGRectMake(margin, 3*margin + SynsetTableViewCell.labelLineHeight + glossSize.height, constrainedSize.width, synonymSize.height))
            synonymLabel.text = synset.synonymsAsString
            synonymLabel.font = caption1Font
            synonymLabel.lineBreakMode = .ByWordWrapping
            synonymLabel.numberOfLines = 0
            synonymLabel.textColor = AppConfiguration.foregroundColor
            backgroundLabel.addSubview(synonymLabel)
        }

        frame.size.height = 4 * SynsetTableViewCell.margin + 2 * SynsetTableViewCell.borderWidth + SynsetTableViewCell.labelLineHeight + glossSize.height + synonymSize.height
        DMTRACE("Actual height of synset header \(bounds.size.height) = 4 * \(SynsetTableViewCell.margin) + 2 * \(SynsetTableViewCell.borderWidth) + \(SynsetTableViewCell.labelLineHeight) + \(glossSize.height) + \(synonymSize.height)")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        backgroundLabel.backgroundColor = selected ? AppConfiguration.highlightColor : cellBackgroundColor
    }
    
}