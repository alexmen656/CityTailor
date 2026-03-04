//
//  CityTailorUITests.swift
//  CityTailorUITests
//
//  Created by Alex Polan on 5/2/25.
//

import XCTest

final class CityTailorUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        setupSnapshot(app)

        // Skip onboarding so we land directly in the main app
        app.launchArguments += ["-hasLaunchedBefore", "1"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot: Map (Home)

    @MainActor
    func testScreenshot01_Map() throws {
        app.launch()
        // Map tab is the default (tab index 2)
        sleep(2)
        snapshot("01_Map")
    }

    // MARK: - Screenshot: Plans

    @MainActor
    func testScreenshot02_Plans() throws {
        app.launch()
        sleep(1)

        app.buttons["tab_plans"].tap()
        sleep(1)
        snapshot("02_Plans")
    }

    // MARK: - Screenshot: Discover

    @MainActor
    func testScreenshot03_Discover() throws {
        app.launch()
        sleep(1)

        app.buttons["tab_discover"].tap()
        sleep(1)
        snapshot("03_Discover")
    }

    // MARK: - Screenshot: Community

    @MainActor
    func testScreenshot04_Community() throws {
        app.launch()
        sleep(1)

        app.buttons["tab_community"].tap()
        sleep(1)
        snapshot("04_Community")
    }

    // MARK: - Screenshot: Settings

    @MainActor
    func testScreenshot05_Settings() throws {
        app.launch()
        sleep(1)

        app.buttons["tab_settings"].tap()
        sleep(1)
        snapshot("05_Settings")
    }
}

// MARK: - Onboarding Screenshots (separate test class, no hasLaunchedBefore flag)

final class CityTailorOnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        setupSnapshot(app)

        // Reset onboarding state so we see the welcome screen
        app.launchArguments += ["-hasLaunchedBefore", "0"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testScreenshot00_Onboarding() throws {
        app.launch()
        sleep(1)
        snapshot("00_Onboarding")
    }
}
