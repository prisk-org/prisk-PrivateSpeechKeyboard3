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
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        let rootVC: UIViewController
        if AppGroup.defaults.bool(forKey: AppGroupKey.onboardingCompleted) {
            rootVC = RecordingViewController()
        } else {
            rootVC = OnboardingViewController()
        }

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
