import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Rhine", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        if ProcessInfo.processInfo.arguments.contains("--agent-session") {
            window.rootViewController = UINavigationController(rootViewController: AgentSessionViewController())
        } else if ProcessInfo.processInfo.arguments.contains("--foundation-diagnostics") {
            window.rootViewController = UINavigationController(rootViewController: FoundationViewController())
        } else {
            window.rootViewController = GalleryController()
        }
        self.window = window
        window.makeKeyAndVisible()
    }
}
