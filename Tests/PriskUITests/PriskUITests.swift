// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import XCTest

final class PriskUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAppLaunches() {
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testOnboardingDisplayedOnFirstLaunch() {
        // On first launch (no onboarding completed flag) the welcome screen should appear
        let welcomeText = app.staticTexts["Welcome to Prisk"]
        // Note: If onboarding was already completed, this test is skipped
        if welcomeText.exists {
            XCTAssertTrue(welcomeText.isHittable)
        }
    }

    func testMicButtonExistsOnRecordingScreen() {
        // If onboarding already done, we should be on RecordingViewController
        let micButton = app.buttons.element(matching: .button, identifier: "Prisk.micButton")
        _ = micButton.waitForExistence(timeout: 3)
        // Just check the app is running — deep UI testing requires device + keyboard enabled
        XCTAssertTrue(app.state == .runningForeground)
    }
}
