//
//  LoginUITests.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import XCTest

final class LoginUITests: XCTestCase {

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-signed-out"]
        app.launch()
        return app
    }

    func test_happyPath_validCredentials_reachesOddsList() {
        let app = launchApp()

        app.textFields["loginEmailField"].tap()
        app.textFields["loginEmailField"].typeText(TestCredentials.email)

        app.secureTextFields["loginPasswordField"].tap()
        app.secureTextFields["loginPasswordField"].typeText(TestCredentials.password)

        app.buttons["loginSubmitButton"].tap()

        let arbitrageToggle = app.buttons["arbitrageOnlyToggle"]
        XCTAssertTrue(arbitrageToggle.waitForExistence(timeout: 5))
    }

    func test_errorPath_invalidCredentials_showsErrorMessage() {
        let app = launchApp()

        app.textFields["loginEmailField"].tap()
        app.textFields["loginEmailField"].typeText("noexiste@test.com")

        app.secureTextFields["loginPasswordField"].tap()
        app.secureTextFields["loginPasswordField"].typeText("passwordIncorrecta")

        app.buttons["loginSubmitButton"].tap()

        let errorMessage = app.staticTexts["loginErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
}
