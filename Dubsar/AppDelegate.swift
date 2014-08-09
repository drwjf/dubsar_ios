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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate, DatabaseManagerDelegate {

    var window: UIWindow?
    var alertURL: NSURL?
    let dubsar = "dubsar"

    let databaseManager = DatabaseManager()

    class var instance : AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as AppDelegate
        }
    }

    var navigationController : UINavigationController {
    get {
        return window!.rootViewController as UINavigationController
    }
    }

    private var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var updatePending = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        setupPushNotificationsForApplication(application, withLaunchOptions:launchOptions)
        databaseManager.initialize()
        databaseManager.delegate = self
        return true
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        NSUserDefaults.standardUserDefaults().synchronize()

        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout() // in case of a font change in the settings

        // probably taken care of in the VC's viewWillAppear:
        if let interface = viewController as? DatabaseManagerDelegate {
            databaseManager.delegate = interface
        }

        checkOfflineSetting()
    }

    func applicationDidEnterBackground(theApplication: UIApplication!) {
        voidCache()
        NSUserDefaults.standardUserDefaults().synchronize()

        // if a bg task is already running, let it go. or if no download in progress, nothing to do.
        if bgTask != UIBackgroundTaskInvalid || !databaseManager.downloadInProgress {
            return
        }

        /*
         * If a download is in progress when we enter the background, we first cancel
         * from the main thread, leaving any partial download in Caches.
         */
        databaseManager.cancelDownload()
        databaseManager.delegate = self // avoid calling back any VC in the bg

        /*
         * Now we kick off a fresh download from the BG. This will use an If-Range header
         * to pick up where the original download left off. Callbacks are performed on
         * the thread that initiates the NSURLConnection request.
         */
        bgTask = theApplication.beginBackgroundTaskWithExpirationHandler() {
            [weak self] in

            if let my = self {
                // just cancel the download if the task expires
                my.databaseManager.cancelDownload()

                if theApplication.applicationState == .Active {
                    /*
                     * If in the meantime, the app has become
                     * active again, and this background task has expired, just kick off a new
                     * background download to pick up where we left off. If the app goes into the
                     * bg after that, that download will go into the bg again as a background task.
                     * DEBT: Is it possible to run background tasks when the app is in the foreground?
                     * Is there any sense to making the download a background task every time and just
                     * letting them continue if the app enters the background?
                     */
                    my.databaseManager.downloadInBackground()
                }
                else {
                    var localNotif = UILocalNotification()
                    localNotif.alertBody = "Background download expired"

                    theApplication.presentLocalNotificationNow(localNotif)

                    my.databaseManager.reportError(localNotif.alertBody)
                    AppConfiguration.offlineSetting = my.databaseManager.fileExists // may have rolled back to an old DB if the DL fails
                }

                theApplication.endBackgroundTask(my.bgTask)
                my.bgTask = UIBackgroundTaskInvalid
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            [weak self] in

            if let my = self {
                // initiate the background download
                // (in the foreground. in the background. that is, in the foreground in the background.)
                my.databaseManager.downloadSynchronous()

                // generate a local notification
                var localNotif = UILocalNotification()
                if (my.databaseManager.errorMessage) {
                    // failure
                    localNotif.alertBody = "Download failed: \(my.databaseManager.errorMessage)"
                }
                else {
                    // success
                    localNotif.alertBody = "Database updated"
                }

                theApplication.presentLocalNotificationNow(localNotif)
                
                theApplication.endBackgroundTask(my.bgTask)
                my.bgTask = UIBackgroundTaskInvalid
            }
        }
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication!) {
        voidCache()
    }

    func application(application: UIApplication!, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData!) {
        DubsarServer.postDeviceToken(deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        DMERROR("application did fail (or as we say in English, failed) to register for remote notifications: \(error.localizedDescription)")
    }

    func application(application: UIApplication!, didReceiveLocalNotification notification: UILocalNotification!) {
        DMINFO("Received local notification: \(notification.alertBody)")
        /* not really necessary
        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout()
        // */
    }

    func application(application: UIApplication, didReceiveRemoteNotification notification: NSDictionary?) {
        if !notification {
            return
        }

        // Custom (Dubsar) payload handling
        let dubsarPayload = notification!.objectForKey(dubsar) as? NSDictionary
        DubsarModelsDailyWord.updateWotdWithNotificationPayload(dubsarPayload)

        let url = dubsarPayload?.objectForKey("url") as? NSString
        if url {
            alertURL = NSURL(string:url)
        }
        else {
            alertURL = nil
        }

        // Standard APNS payload handling
        let aps = notification?.objectForKey("aps") as? NSDictionary
        let alert = aps?.objectForKey("alert") as? NSString

        switch (application.applicationState) {
        case .Active:
            showAlert(alert)

        default:
            openURL(alertURL)
            alertURL = nil
        }
    }

    func application(theApplication: UIApplication!, handleActionWithIdentifier identifier: String!, forRemoteNotification userInfo: NSDictionary!, completionHandler: (() -> Void)!) {
        DMINFO("Received remote notification action \(identifier)")
        application(theApplication, didReceiveRemoteNotification: userInfo)
    }

    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        let scheme = url.scheme
        if scheme != dubsar {
            return false
        }

        let path = url.path
        var word : DubsarModelsWord!
        var title : String?
        if path.hasPrefix("/wotd/") {
            let last = url.lastPathComponent as NSString
            let wotdId = UInt(last.intValue)
            word = DubsarModelsWord(id: wotdId, name: nil, partOfSpeech: .Unknown) // load the name and pos from the DB by ID
            title = "Word of the Day"
        }
        else if path.hasPrefix("/words/") {
            let last = url.lastPathComponent as NSString
            let wotdId = UInt(last.intValue)
            word = DubsarModelsWord(id: wotdId, name: nil, partOfSpeech: .Unknown) // load the name and pos from the DB by ID
        }

        let top = navigationController.topViewController as BaseViewController

        navigationController.dismissViewControllerAnimated(true, completion: nil)
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in

            if let my = self {
                let viewController : BaseViewController! = top.instantiateViewControllerWithIdentifier(WordViewController.identifier, router: nil)
                if title {
                    viewController.title = title
                }
                viewController.router = Router(viewController: viewController, model: word)
                my.navigationController.pushViewController(viewController, animated: true)
            }
        }

        DMTRACE("push \(WordViewController.identifier) view controller")
        return true
    }

    func application(application: UIApplication!, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings!) {
        DMTRACE("Application did register user notification settings")
    }

    func voidCache() {
        NavButtonImage.voidCache()
        DownloadButtonImage.voidCache()
        CGHelper.voidCache()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex index: Int) {
        if index == 0 {
            /*
             * If the question was stop or continue the download, getting here means continue.
             * In either case, we don't change the preference setting.
             *
             * The only other time we get here is if the user changes a setting, in the Settings view or the
             * Settings app, and then cancels. We then revert the setting, assuming they've changed their mind,
             * or the original change was an accident.
             */
            if !alertURL && !databaseManager.downloadInProgress {
                AppConfiguration.offlineSetting = !AppConfiguration.offlineSetting
                let viewController = navigationController.topViewController as BaseViewController
                viewController.adjustLayout()
            }

            return
        }

        if alertURL {
            openURL(alertURL)
            alertURL = nil
            return
        }

        if (databaseManager.downloadInProgress) {
            databaseManager.cancelDownload()
            AppConfiguration.offlineSetting = databaseManager.fileExists // may have rolled back to an old DB in case of DL failure.
        }
        else if (updatePending || AppConfiguration.offlineSetting) {
            databaseManager.download()
        }
        else {
            databaseManager.deleteDatabase()
        }

        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout()

        updatePending = false
    }

    func databaseManager(theDatabaseManager: DatabaseManager!, encounteredError errorMessage: String!) {
        AppConfiguration.offlineSetting = theDatabaseManager.fileExists // may have rolled back to an old DB in case of DL failure.
        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout()
    }

    func downloadComplete(databaseManager: DatabaseManager!) {
        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout()
    }

    func newDownloadAvailable(theDatabaseManager: DatabaseManager!, name downloadName: String!, zipped zippedSize: UInt, unzipped unzippedSize: UInt) {
        if !AppConfiguration.offlineSetting {
            // this can change in the interim. the checkForUpdate() request doesn't take long, so the user just set the offline switch to off.
            return
        }

        if AppConfiguration.autoUpdateSetting {
            theDatabaseManager.download()
            let viewController = navigationController.topViewController as BaseViewController
            viewController.adjustLayout()
            return
        }

        let zippedMB = Int(Double(zippedSize)/Double(1024)/Double(1024) + 0.5)
        let unzippedMB = Int(Double(unzippedSize)/Double(1024)/Double(1024) + 0.5)

        // Alert user.
        let message = "An updated database is available. It's a \(zippedMB) MB download and \(unzippedMB) MB on the device. Download and install?"
        let alert = UIAlertView(title: "New download available", message: message, delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Download")
        alert.show()
        updatePending = true
    }

    func checkOfflineSetting() {
        databaseManager.rootURL = AppConfiguration.rootURL

        // consistency check. the user changed the setting in the Settings app or the Settings view

        // in case we're preparing an alert
        var message: String
        var okTitle: String
        var cancelTitle: String

        let offlineSetting = AppConfiguration.offlineSetting
        if databaseManager.downloadInProgress {
            if (offlineSetting) {
                DMTRACE("Download in progress")
                return // happy. DEBT: Do we need to check for update? If a DL is in progress, we probably just checked.
            }
            else {
                message = "Stop the download in progress?"
                okTitle = "Stop"
                cancelTitle = "Continue"
            }
        }
        else if offlineSetting == databaseManager.fileExists {
            if offlineSetting {
                DMDEBUG("\(databaseManager.fileURL.path) exists. checking for updates")
                databaseManager.checkForUpdate()
            }
            return
        }
        else if offlineSetting {
            DMTRACE("No database. Offline setting is on. Getting download list.")
            databaseManager.checkForUpdate()
            return
        }
        else {
            message = "Delete the database? You can download it again if you change your mind."
            okTitle = "Delete"
            cancelTitle = "Cancel"
        }

        let alert = UIAlertView(title: "Offline setting changed", message: message, delegate: self, cancelButtonTitle: cancelTitle, otherButtonTitles: okTitle)
        alert.show()
    }

    func setupPushNotificationsForApplication(theApplication:UIApplication, withLaunchOptions launchOptions: NSDictionary?) {
        // register for push notifications
        PushWrapper.register()

        // extract the push payload, if any, from the launchOptions
        let payload = launchOptions?.objectForKey(UIApplicationLaunchOptionsRemoteNotificationKey) as? NSDictionary
        // pass it back to this app. this is where notifications arrive if a notification is tapped while the app is not running. the app is launched by the tap in that case.
        application(theApplication, didReceiveRemoteNotification: payload)
    }

    func showAlert(message: String?) {
        assert(message)
        // https://devforums.apple.com/message/973043#973043
        let alert = UIAlertView()
        alert.title = "Dubsar Alert"
        alert.message = message
        alert.addButtonWithTitle("OK")
        if alertURL {
            alert.addButtonWithTitle("More")
        }
        alert.cancelButtonIndex = 0
        alert.show()
        alert.delegate = self
    }

    func openURL(url: NSURL?) {
        if !url {
            return
        }

        let application = UIApplication.sharedApplication()

        if url!.scheme == dubsar {
            self.application(application, openURL:url, sourceApplication:nil, annotation:nil)
        }
        else {
            // pass http/https URLS to Safari
            application.openURL(url)
        }
    }

}

