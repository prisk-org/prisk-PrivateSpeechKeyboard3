// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        PriskLogger.app.info("SceneDelegate: scene will connect, checking onboarding")
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        let onboardingCompleted = AppGroup.defaults.bool(forKey: AppGroupKey.onboardingCompleted)
        let rootVC: UIViewController
        if onboardingCompleted {
            rootVC = RecordingViewController()
        } else {
            rootVC = OnboardingViewController()
        }
        PriskLogger.app.info("SceneDelegate: rootVC = \(onboardingCompleted ? "RecordingVC" : "OnboardingVC", privacy: .public)")

        window?.rootViewController = UINavigationController(rootViewController: rootVC)
        window?.makeKeyAndVisible()

        // Handle URL open at launch (e.g. keyboard tapped mic)
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }

    // MARK: — URL Scheme Handling

    private func handleURL(_ url: URL) {
        PriskLogger.app.info("SceneDelegate: handleURL called: \(url.absoluteString, privacy: .public)")
        guard url.scheme == "prisk",
              url.host == "start-recording" else { return }

        let lang = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "lang" })?.value

        // Navigate to RecordingViewController and auto-start
        let nav = window?.rootViewController as? UINavigationController
        let recordingVC = RecordingViewController()
        recordingVC.autoStartLanguage = lang
        nav?.setViewControllers([recordingVC], animated: false)
        recordingVC.startRecordingIfNeeded()
    }
}
