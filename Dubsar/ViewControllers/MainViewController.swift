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

class MainViewController: BaseViewController, UIAlertViewDelegate, UISearchBarDelegate {

    // MARK: Storyboard outlets
    @IBOutlet var wotdButton : UIButton!
    @IBOutlet var searchBar : UISearchBar!
    @IBOutlet var wotdLabel : UILabel!
    @IBOutlet var wordNetLabel : UILabel!

    var alphabetView : AlphabetView!
    var autocompleterView : AutocompleterView!
    var wotd : DubsarModelsDailyWord!
    var autocompleter : DubsarModelsAutocompleter?
    var lastSequence : Int = -1
    var searchBarEditing : Bool = false
    var keyboardHeight : CGFloat = 0
    var rotated : Bool = false

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        wotd = DubsarModelsDailyWord()
        wotd.delegate = self

        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)

        // this view resizes its own height
        autocompleterView = AutocompleterView(frame: CGRectMake(0, searchBar.bounds.size.height+searchBar.frame.origin.y, view.bounds.size.width, view.bounds.size.height))
        autocompleterView.hidden = true
        autocompleterView.viewController = self
        view.addSubview(autocompleterView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardShowing:", name: UIKeyboardDidShowNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        wotd.load()
        resetSearch()
        rotated = false
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)
        if let viewController = segue.destinationViewController as? WordViewController {
            viewController.word = wotd.word
            wotd.word.complete = false
            viewController.title = "Word of the Day"
        }
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        /* avoid the default behavior
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation) // calls adjustLayout()
         */
        rotated = true

        let toInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation

        if alphabetView {
            // DEBT: Move this stuff into the AlphabetView
            let π = CGFloat(M_PI)

            var transform = CGAffineTransformIdentity

            // position the alphabet view at its original position after rotation
            // In each case, move the view to its current location in the new view frame, without resizing, so that the lower
            // righthand corner of the alphabetView is in the lower righthand corner of the view before the rotation begins.
            alphabetView.frame.origin.x = view.bounds.size.width - alphabetView.bounds.size.width
            alphabetView.frame.origin.y = view.bounds.size.height - alphabetView.bounds.size.height

            assert(alphabetView.frame.origin.x + alphabetView.bounds.size.width == view.bounds.size.width)
            assert(alphabetView.frame.origin.y + alphabetView.bounds.size.height == view.bounds.size.height)

            var inset: CGFloat = 0
            //*
            // Then rotate around that lower righthand corner in each case, rather than the center of the view.
            if UIInterfaceOrientationIsPortrait(toInterfaceOrientation) {
                // alphabetView.frame.size.width = view.bounds.size.width

                // rotating from the bottom of the view to the right side
                let aspect = (view.bounds.size.height - searchBar.bounds.size.height) / alphabetView.bounds.size.width
                inset = 0.5 * alphabetView.bounds.size.height
                transform = CGAffineTransformTranslate(transform, 0.5*aspect*alphabetView.bounds.size.width - inset, 0.0)
                transform = CGAffineTransformRotate(transform, 0.5 * π)
                transform = CGAffineTransformTranslate(transform, -0.5*aspect*alphabetView.bounds.size.width + inset, 0.0)
                transform = CGAffineTransformScale(transform, aspect, 1.0)
            }
            else {
                // alphabetView.frame.size.height = view.bounds.size.height - searchBar.bounds.size.height

                // rotating from the right side of the view to the bottom
                let aspect = view.bounds.width / alphabetView.bounds.size.height
                inset = 0.5 * alphabetView.bounds.size.width
                transform = CGAffineTransformTranslate(transform, 0.0, 0.5*aspect*alphabetView.bounds.size.height - inset)
                transform = CGAffineTransformRotate(transform, -0.5 * π)
                transform = CGAffineTransformTranslate(transform, 0.0, -0.5*aspect*alphabetView.bounds.size.height + inset)
                transform = CGAffineTransformScale(transform, 1.0, aspect)
            }

            UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveLinear,
                animations: {
                    [weak self] in
                    if let my = self {
                        my.alphabetView.transform = transform
                    }
                },
                completion: {
                    [weak self]
                    (finished: Bool) in
                    if finished {
                        self?.adjustAlphabetView(toInterfaceOrientation)
                    }
                })
            // */
        }
    }

    // MARK: UISearchBarDelegate
    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool {
        searchBar.showsCancelButton = true
        searchBarEditing = true
        return true
    }

    func searchBarDidEndEditing(searchBar: UISearchBar!) {
        resetSearch()
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        resetSearch()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
        let search = DubsarModelsSearch(term: searchBar.text, matchCase: false)
        resetSearch()
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search)
    }

    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
        autocompleter?.cancel()

        if !searchBarEditing || searchText.isEmpty {
            autocompleterView.hidden = true
            return
        }

        if !rotated {
            triggerAutocompletion()
        }
        // else wait for keyboardShown: to be called to recompute the keyboard height
    }

    // MARK: DubsarModelsLoadDelegate
    override func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        if let a = model as? DubsarModelsAutocompleter {
            if a.seqNum < lastSequence {
                return
            }
            autocompleterFinished(a, withError: nil)
        }
        else if let dailyWord = model as? DubsarModelsDailyWord {
            /*
             * First determine the ID of the WOTD by consulting the user defaults or requesting
             * from the server. Once we have that, load the actual word entry for info to display.
             */
            dailyWord.word.delegate = self
            dailyWord.word.load()
        }
        else if let word = model as? DubsarModelsWord {
            /*
             * Now we've loaded the word from the DB. Display it.
             */

            wotdButton.setTitle(word.nameAndPos, forState: .Normal)
        }

    }

    func autocompleterFinished(theAutocompleter: DubsarModelsAutocompleter!, withError error: String!) {
        // NSLog("Autocompleter finished for term %@, seq. %d, result count %d", theAutocompleter.term, theAutocompleter.seqNum, theAutocompleter.results.count)
        if !searchBarEditing || searchBar.text.isEmpty {
            return
        }

        autocompleterView.autocompleter = theAutocompleter
        autocompleterView.hidden = false
    }

    override func adjustLayout() {
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        wotdLabel.font = font
        wotdButton.titleLabel.font = font
        wordNetLabel.font = font

        // rerun the autocompletion request with the new max
        searchBar(searchBar, textDidChange: searchBar.text)

        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)

        super.adjustLayout()
    }

    func triggerAutocompletion() {
        // compute available space
        let available = view.bounds.size.height - keyboardHeight - searchBar.bounds.size.height
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let margin = AutocompleterView.margin
        let lineHeight = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: font]).height + 3*margin

        var max: UInt = UInt(available / lineHeight) // floor
        if max < 1 {
            max = 1
        }

        // NSLog("avail. ht: %f, lineHeight: %f, max: %d", available, lineHeight, max)

        // NSLog("Autocompletion text: %@", searchText)
        autocompleter = DubsarModelsAutocompleter(term: searchBar.text, matchCase: false)
        autocompleter!.delegate = self
        autocompleter!.max = max
        autocompleter!.load()
        lastSequence = autocompleter!.seqNum
    }

    func resetSearch() {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.showsCancelButton = false

        autocompleterView.hidden = true
        searchBarEditing = false
    }

    func autocompleterView(_: AutocompleterView!, selectedResult result: String!) {
        let search = DubsarModelsSearch(term: result, matchCase: false)
        resetSearch()
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search)
    }

    func keyboardShowing(notification: NSNotification!) {
        keyboardHeight = KeyboardHelper.keyboardSizeFromNotification(notification)

        // why does this crash?
        // NSLog("Keyboard height is %f, rotated = %@", keyboardHeight, (rotated ? "true" : "false"))

        if rotated {
            triggerAutocompletion()
            rotated = false
        }
    }

    private func computeAlphabetFrame(orientation: UIInterfaceOrientation) -> CGRect {
        var alphabetFrame = CGRectZero
        let dimension : CGFloat = 50

        if UIInterfaceOrientationIsPortrait(orientation) {
            alphabetFrame = CGRectMake(view.bounds.size.width - dimension, searchBar.bounds.size.height, dimension, view.bounds.size.height - searchBar.bounds.size.height)
            // NSLog("portrait: frame (%f, %f) %f x %f", Double(alphabetFrame.origin.x), Double(alphabetFrame.origin.y), Double(alphabetFrame.size.width), Double(alphabetFrame.size.height))
        }
        else {
            alphabetFrame = CGRectMake(0, view.bounds.size.height - dimension, view.bounds.size.width, dimension)
            // NSLog("landscape: frame (%f, %f) %f x %f", Double(alphabetFrame.origin.x), Double(alphabetFrame.origin.y), Double(alphabetFrame.size.width), Double(alphabetFrame.size.height))
        }

        return alphabetFrame
    }

    func adjustAlphabetView(orientation: UIInterfaceOrientation) {
        // NSLog("adjusting alphabet view")
        var alphabetFrame = CGRectZero
        if !alphabetView {
            alphabetView = AlphabetView(frame: alphabetFrame)
            alphabetView.viewController = self
            view.addSubview(alphabetView)
        }

        alphabetFrame = computeAlphabetFrame(orientation)

        let dimension: CGFloat = 50 // DEBT <-
        alphabetView.transform = CGAffineTransformIdentity
        alphabetView.frame = alphabetFrame
        alphabetView.hidden = false
        alphabetView.setNeedsLayout()
    }

    func alphabetView(_:AlphabetView!, selectedButton button: GlobButton!) {
        let search = DubsarModelsSearch(wildcard: button.globExpression, page: 1, title: button.titleForState(.Normal))
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search)
    }
}