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

enum RouterAction {
    case UpdateView
    case UpdateRowAtIndexPath
    case UpdateViewWithDependency // may be clear enough or may need an index path
    case UpdateAutocompleter
}

class Router: NSObject, DubsarModelsLoadDelegate {

    var viewController: BaseViewController
    var model: DubsarModelsModel
    var routerAction = RouterAction.UpdateView
    var indexPath: NSIndexPath?

    init(viewController: BaseViewController!, model: DubsarModelsModel!) {
        self.viewController = viewController
        self.model = model

        super.init()

        model.delegate = self
    }

    func load() {
        model.load()
    }

    func loadComplete(model: DubsarModelsModel!, withError error: String!) {
        viewController.routeResponse(self)
    }
}
