import XCTest

final class OneLifeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsPlannerShell() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["finance-tab"].exists)
        XCTAssertTrue(app.buttons["relationships-tab"].exists)
        XCTAssertTrue(app.buttons["health-tab"].exists)
        XCTAssertTrue(app.buttons["life-tab"].exists)
        XCTAssertTrue(app.buttons["age-up-button"].exists)
        XCTAssertTrue(app.otherElements["life-signals"].exists)
        XCTAssertTrue(app.otherElements["career-tab-content"].exists || app.otherElements["education-tab-content"].exists)
    }

    @MainActor
    func testTabsSwitchWithoutLosingPrimaryAction() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["age-up-button"].exists)

        app.buttons["relationships-tab"].tap()
        XCTAssertTrue(app.otherElements["relationships-tab-content"].waitForExistence(timeout: 2))

        app.buttons["health-tab"].tap()
        XCTAssertTrue(app.otherElements["health-tab-content"].waitForExistence(timeout: 2))

        app.buttons["life-tab"].tap()
        XCTAssertTrue(app.otherElements["life-tab-content"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTeenEducationPlannerShowsGuidanceSections() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.otherElements["education-teen-strip"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["education-school-climate"].exists)
        XCTAssertTrue(app.otherElements["education-pressure-sources"].exists)
        XCTAssertTrue(app.otherElements["education-next-unlocks"].exists)
        XCTAssertTrue(app.buttons["Lock In"].exists)
        XCTAssertTrue(app.buttons["Join Activity"].exists)
        XCTAssertTrue(app.buttons["Lay Low"].exists)
        XCTAssertFalse(app.buttons["Job Hunt"].exists)
    }

    @MainActor
    func testTeenFinanceTabShowsPocketCashFraming() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Pocket Cash"].exists)
        XCTAssertTrue(app.buttons["Small Hustle"].exists)
        XCTAssertTrue(app.otherElements["action-preview-strip"].exists)
    }

    @MainActor
    func testStartupFlowTransitionsIntoPlannerShell() throws {
        let app = launchApp()

        if app.otherElements["startup-screen"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.buttons["quick-start-button"].exists)
            XCTAssertTrue(app.buttons["begin-life-button"].exists)

            app.buttons["begin-life-button"].tap()
            dismissLaunchEventIfNeeded(app)
        } else {
            dismissLaunchEventIfNeeded(app)
        }

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["age-up-button"].exists)
        XCTAssertTrue(app.otherElements["life-signals"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
        }
    }

    @MainActor
    func testDebugScenarioLabIsReachableFromSettings() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["settings-button"].tap()
        XCTAssertTrue(app.buttons["Open QA Scenarios"].waitForExistence(timeout: 2))
        app.buttons["Open QA Scenarios"].tap()

        XCTAssertTrue(app.otherElements["debug-scenario-lab"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["debug-scenario-adultCareerFlow"].exists)
    }

    @MainActor
    func testDirectLaunchIntoAdultCareerScenarioShowsAdultActions() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Work Hard"].exists)
        XCTAssertTrue(app.buttons["Job Hunt"].exists)
        XCTAssertFalse(app.otherElements["startup-screen"].exists)
    }

    @MainActor
    func testDirectLaunchIntoPregnancyScenarioShowsRelationshipState() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "pregnancyYoungFamily"
        ])

        XCTAssertTrue(app.otherElements["relationships-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Pregnant with Owen"].exists)
        XCTAssertTrue(app.buttons["Repair Tension"].exists)
    }

    @MainActor
    func testDirectLaunchIntoEventPreviewShowsEventSheet() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "eventPreview",
            "-debug-modal", "event"
        ])

        XCTAssertTrue(app.otherElements["event-sheet"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["event-choice-0"].exists)
    }

    @MainActor
    func testDirectLaunchIntoYearSummaryPreviewShowsSummarySheet() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "yearSummaryPreview",
            "-debug-modal", "yearSummary"
        ])

        XCTAssertTrue(app.otherElements["year-summary-sheet"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["year-summary-continue-button"].exists)
    }

    @MainActor
    func testAdultCareerAndFinanceDrilldownsOpen() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        app.buttons["career-overview-detail-button"].tap()
        XCTAssertTrue(app.otherElements["detail-sheet-careerOverview"].waitForExistence(timeout: 2))

        app.buttons["planner-detail-done-button"].tap()
        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        app.buttons["finance-investing-detail-button"].tap()
        XCTAssertTrue(app.otherElements["detail-sheet-financeInvesting"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFamilyAndHousingDrilldownsOpenFromDebugStates() throws {
        let familyApp = launchApp(arguments: [
            "-debug-scenario", "pregnancyYoungFamily"
        ])

        XCTAssertTrue(familyApp.otherElements["relationships-tab-content"].waitForExistence(timeout: 2))
        familyApp.buttons["relationships-family-detail-button"].tap()
        XCTAssertTrue(familyApp.otherElements["detail-sheet-relationshipsFamily"].waitForExistence(timeout: 2))

        let housingApp = launchApp(arguments: [
            "-debug-scenario", "housingDeficitFlow"
        ])

        XCTAssertTrue(housingApp.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        housingApp.buttons["life-tab"].tap()
        XCTAssertTrue(housingApp.otherElements["life-tab-content"].waitForExistence(timeout: 2))
        housingApp.buttons["life-housing-detail-button"].tap()
        XCTAssertTrue(housingApp.otherElements["detail-sheet-lifeHousing"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLargeContentSizeStillKeepsPlannerReachable() throws {
        let app = launchApp(environment: [
            "UIPreferredContentSizeCategoryName": "UICTContentSizeCategoryXXXL"
        ])

        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.buttons["age-up-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["life-signals"].exists)
    }

    @MainActor
    func testPlannerAccessibilityAudit() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .dynamicType])
    }

    @MainActor
    private func enterPlannerShellIfNeeded(_ app: XCUIApplication) {
        if app.otherElements["startup-screen"].waitForExistence(timeout: 2) {
            let beginButton = app.buttons["begin-life-button"]
            XCTAssertTrue(beginButton.waitForExistence(timeout: 2))
            beginButton.tap()
        }

        dismissLaunchEventIfNeeded(app)
    }

    @MainActor
    private func dismissLaunchEventIfNeeded(_ app: XCUIApplication) {
        if app.navigationBars["Year Event"].waitForExistence(timeout: 2) {
            let firstChoice = app.buttons.element(boundBy: 0)
            XCTAssertTrue(firstChoice.waitForExistence(timeout: 2))
            firstChoice.tap()
        }
    }

    private func launchApp(arguments: [String] = [], environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: arguments)
        app.launchEnvironment.merge(environment) { _, new in new }
        app.launch()
        return app
    }
}
