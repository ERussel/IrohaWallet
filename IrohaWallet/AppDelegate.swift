import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        do {
            let window = UIWindow()
            self.window = window

            let context = try ContextFactory.createContext()

            window.rootViewController = try context.createRootController()
            window.makeKeyAndVisible()

            return true
        } catch {
            return false
        }
    }
}

