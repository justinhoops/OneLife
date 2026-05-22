import XCTest

final class OneLifeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testLaunchShowsPlannerShell() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.buttons["home-tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["career-tab"].exists)
        XCTAssertTrue(app.buttons["finance-tab"].exists)
        XCTAssertTrue(app.buttons["relationships-tab"].exists)
        XCTAssertTrue(app.buttons["body-tab"].exists)
        XCTAssertTrue(app.buttons["history-tab"].exists)
        XCTAssertFalse(app.buttons["feed-tab"].exists)
        XCTAssertFalse(app.buttons["life-tab"].exists)
        XCTAssertTrue(app.otherElements["bottom-game-bar"].exists)
        XCTAssertTrue(app.buttons["bottom-actions-menu"].exists)
        XCTAssertTrue(app.otherElements["bottom-domain-strip"].exists)
        XCTAssertTrue(app.buttons["age-up-button"].exists)
        XCTAssertTrue(app.buttons["open-life-feed-button"].exists)

        openLifeFeed(from: app)
        XCTAssertTrue(element("feed-tab-content", in: app).waitForExistence(timeout: 5))
        dismissLifeFeedIfPresent(app)
    }

    @MainActor
    func testTabsSwitchWithoutLosingPrimaryAction() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["home-tab"].tap()
        XCTAssertTrue(app.otherElements["home-tab-content"].waitForExistence(timeout: 2))

        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2) || app.otherElements["education-tab-content"].waitForExistence(timeout: 2))

        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["assets-housing-legacy-section"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["age-up-button"].exists)
        XCTAssertTrue(app.buttons["bottom-actions-menu"].exists)

        app.buttons["relationships-tab"].tap()
        XCTAssertTrue(app.otherElements["relationships-tab-content"].waitForExistence(timeout: 2))

        app.buttons["body-tab"].tap()
        XCTAssertTrue(app.otherElements["health-tab-content"].waitForExistence(timeout: 2))

        app.buttons["history-tab"].tap()
        XCTAssertTrue(app.otherElements["history-tab-content"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSpecialCareerCrimeScenarioShowsCrimeInCareerTab() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "specialCareerCrime"
        ])

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 5))
        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 5))
        if !element("crime-career-section", in: app).waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(element("crime-career-section", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testTeenEducationPlannerShowsGuidanceSections() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["education-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["education-overview-header"].exists)
        XCTAssertTrue(app.otherElements["work-overview-audit"].exists)
        XCTAssertTrue(app.otherElements["work-overview-pressure"].exists)
        XCTAssertTrue(app.buttons["action-choice-studyConsistently"].exists)
        XCTAssertTrue(app.buttons["action-choice-joinClub"].exists)
        XCTAssertFalse(app.buttons["action-choice-jobHunt"].exists)
    }

    @MainActor
    func testTeenFinanceTabShowsPocketCashFraming() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Cash"].exists)
        XCTAssertTrue(app.otherElements["money-overview-audit"].exists)
        XCTAssertTrue(app.otherElements["money-overview-pressure"].exists)
        XCTAssertTrue(app.buttons["action-choice-smallHustle"].exists)
        XCTAssertTrue(app.otherElements["action-preview-strip"].exists)
    }

    @MainActor
    func testStartupFlowTransitionsIntoPlannerShell() throws {
        let app = launchApp()

        if element("startup-screen", in: app).waitForExistence(timeout: 2) || app.buttons["begin-life-button"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.buttons["quick-start-button"].exists)
            XCTAssertTrue(app.buttons["begin-life-button"].exists)

            app.buttons["begin-life-button"].tap()
            dismissLaunchEventIfNeeded(app)
        } else {
            dismissLaunchEventIfNeeded(app)
        }

        XCTAssertTrue(app.buttons["home-tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["career-tab"].exists)
        XCTAssertTrue(app.buttons["age-up-button"].exists)
        XCTAssertTrue(app.buttons["open-life-feed-button"].exists)
        openLifeFeed(from: app)
        XCTAssertTrue(element("feed-tab-content", in: app).exists)
        XCTAssertTrue(element("feed-overview-header", in: app).exists)
        dismissLifeFeedIfPresent(app)
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

        XCTAssertTrue(app.buttons["debug-scenario-adultCareerFlow"].waitForExistence(timeout: 4))
    }

    @MainActor
    func testDirectLaunchIntoAdultCareerScenarioShowsAdultActions() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 2))
        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(reveal(app.buttons["action-choice-workHard"], in: app))
        XCTAssertTrue(reveal(app.buttons["action-choice-jobHunt"], in: app))
        XCTAssertFalse(element("startup-screen", in: app).exists)
    }

    @MainActor
    func testDirectLaunchIntoPregnancyScenarioShowsRelationshipState() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "pregnancyYoungFamily"
        ])

        XCTAssertTrue(app.buttons["relationships-tab"].waitForExistence(timeout: 2))
        app.buttons["relationships-tab"].tap()
        XCTAssertTrue(app.otherElements["relationships-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Pregnant with Owen"].waitForExistence(timeout: 2))
        XCTAssertTrue(reveal(app.buttons["action-choice-repairTension"], in: app))
    }

    @MainActor
    func testAgeUpStartsForecastBeforeEventAndDisablesPrimaryAction() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        let ageUpButton = app.buttons["age-up-button"]
        XCTAssertTrue(ageUpButton.waitForExistence(timeout: 2))
        ageUpButton.tap()

        XCTAssertTrue(element("forecast-sheet", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(ageUpButton.isEnabled)
        XCTAssertTrue(app.buttons["forecast-continue-button"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testForecastThenEventThenReactionFlowAppearsInOrder() throws {
        let app = launchApp()

        enterPlannerShellIfNeeded(app)

        app.buttons["age-up-button"].tap()
        XCTAssertTrue(element("forecast-sheet", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["forecast-continue-button"].waitForExistence(timeout: 2))
        app.buttons["forecast-continue-button"].tap()
        XCTAssertTrue(element("event-sheet", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["event-choice-0"].waitForExistence(timeout: 2))
        app.buttons["event-choice-0"].tap()

        let reactionAppeared = element("reaction-sheet", in: app).waitForExistence(timeout: 2)
        let summaryAppeared = element("year-summary-sheet", in: app).waitForExistence(timeout: 2)
        XCTAssertTrue(reactionAppeared || summaryAppeared)
    }

    @MainActor
    func testDirectLaunchIntoEventPreviewShowsEventSheet() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "eventPreview",
            "-debug-modal", "event"
        ])

        XCTAssertTrue(element("event-sheet", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["event-choice-0"].exists)
    }

    @MainActor
    func testDirectLaunchIntoYearSummaryPreviewShowsSummarySheet() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "yearSummaryPreview",
            "-debug-modal", "yearSummary"
        ])

        XCTAssertTrue(element("year-summary-sheet", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["year-summary-continue-button"].exists)
    }

    @MainActor
    func testAdultCareerAndFinanceDrilldownsOpen() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 2))
        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        app.buttons["career-overview-detail-button"].tap()
        XCTAssertTrue(element("detail-sheet-careerOverview", in: app).waitForExistence(timeout: 2))

        app.buttons["planner-detail-done-button"].tap()
        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        app.buttons["finance-cashflow-detail-button"].tap()
        XCTAssertTrue(element("detail-sheet-financeCashflow", in: app).waitForExistence(timeout: 2))
    }

    @MainActor
    func testPrimaryTabsKeepSelectedActionVisible() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 2))
        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["work-overview-pressure"].exists)
        XCTAssertTrue(app.buttons["action-choice-workHard"].exists)

        app.buttons["action-choice-jobHunt"].tap()
        XCTAssertTrue(app.buttons["age-up-button"].exists)
        XCTAssertTrue(app.buttons["action-choice-jobHunt"].exists)
    }

    @MainActor
    func testFamilyAndHousingDrilldownsOpenFromDebugStates() throws {
        let familyApp = launchApp(arguments: [
            "-debug-scenario", "pregnancyYoungFamily"
        ])

        XCTAssertTrue(familyApp.buttons["relationships-tab"].waitForExistence(timeout: 2))
        familyApp.buttons["relationships-tab"].tap()
        XCTAssertTrue(familyApp.otherElements["relationships-tab-content"].waitForExistence(timeout: 2))
        familyApp.buttons["relationships-family-detail-button"].tap()
        XCTAssertTrue(element("detail-sheet-relationshipsFamily", in: familyApp).waitForExistence(timeout: 2))

        let housingApp = launchApp(arguments: [
            "-debug-scenario", "housingDeficitFlow"
        ])

        XCTAssertTrue(housingApp.buttons["finance-tab"].waitForExistence(timeout: 2))
        housingApp.buttons["finance-tab"].tap()
        XCTAssertTrue(housingApp.otherElements["finance-tab-content"].waitForExistence(timeout: 2))
        XCTAssertTrue(reveal(housingApp.buttons["life-housing-detail-button"], in: housingApp))
        housingApp.buttons["life-housing-detail-button"].tap()
        XCTAssertTrue(element("detail-sheet-lifeHousing", in: housingApp).waitForExistence(timeout: 2))
    }

    @MainActor
    func testLargeContentSizeStillKeepsPlannerReachable() throws {
        let app = launchApp(environment: [
            "UIPreferredContentSizeCategoryName": "UICTContentSizeCategoryXXXL"
        ])

        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.buttons["age-up-button"].waitForExistence(timeout: 3))
        openLifeFeed(from: app)
        XCTAssertTrue(app.otherElements["life-signals"].exists)
        dismissLifeFeedIfPresent(app)
    }

    @MainActor
    func testPlannerAccessibilityAudit() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])

        XCTAssertTrue(app.buttons["career-tab"].waitForExistence(timeout: 2))
        app.buttons["career-tab"].tap()
        XCTAssertTrue(app.otherElements["career-tab-content"].waitForExistence(timeout: 2))
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .dynamicType])
    }

    @MainActor
    private func enterPlannerShellIfNeeded(_ app: XCUIApplication) {
        if element("startup-screen", in: app).waitForExistence(timeout: 2) || app.buttons["begin-life-button"].waitForExistence(timeout: 2) {
            let beginButton = app.buttons["begin-life-button"]
            XCTAssertTrue(beginButton.waitForExistence(timeout: 2))
            beginButton.tap()
        }

        dismissLaunchEventIfNeeded(app)
    }

    @MainActor
    private func openLifeFeed(from app: XCUIApplication) {
        XCTAssertTrue(app.buttons["open-life-feed-button"].waitForExistence(timeout: 5))
        app.buttons["open-life-feed-button"].tap()
        XCTAssertTrue(element("feed-tab-content", in: app).waitForExistence(timeout: 10))
    }

    @MainActor
    private func dismissLifeFeedIfPresent(_ app: XCUIApplication) {
        let done = app.navigationBars.buttons["Done"]
        if done.waitForExistence(timeout: 2) {
            done.tap()
        }
    }

    @MainActor
    private func dismissLaunchEventIfNeeded(_ app: XCUIApplication) {
        for _ in 0..<6 {
            if app.buttons["forecast-continue-button"].exists {
                app.buttons["forecast-continue-button"].tap()
                continue
            }

            if app.buttons["event-choice-0"].exists {
                app.buttons["event-choice-0"].tap()
                continue
            }

            if app.buttons["reaction-continue-button"].exists {
                app.buttons["reaction-continue-button"].tap()
                continue
            }

            if app.buttons["year-summary-continue-button"].exists {
                app.buttons["year-summary-continue-button"].tap()
                continue
            }

            if app.buttons["planner-detail-done-button"].exists {
                app.buttons["planner-detail-done-button"].tap()
                continue
            }

            if element("forecast-sheet", in: app).exists ||
                element("event-sheet", in: app).exists ||
                element("reaction-sheet", in: app).exists ||
                element("year-summary-sheet", in: app).exists {
                continue
            }

            if app.buttons["age-up-button"].waitForExistence(timeout: 1) {
                return
            }

            break
        }
    }

    @MainActor
    func testAdultCareerScenarioHomeShowsQuickActionsAndSystemsStrip() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])
        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(element("home-tab", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["home-tab-content"].exists)
        XCTAssertTrue(app.otherElements["home-opportunities"].exists)
        XCTAssertTrue(app.buttons["action-choice-workHard"].exists)
        XCTAssertTrue(element("finance-tab", in: app).exists)
    }

    @MainActor
    func testBottomFinanceButtonSelectsFinancePanel() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])
        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.otherElements["home-tab-content"].waitForExistence(timeout: 3))
        app.buttons["finance-tab"].tap()
        XCTAssertTrue(app.otherElements["finance-tab-content"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeActionTapSurfacesPulseBanner() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])
        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(app.buttons["home-tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(reveal(app.buttons["action-choice-workHard"], in: app))
        app.buttons["action-choice-workHard"].tap()
        XCTAssertTrue(app.otherElements["activity-pulse-banner"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFinanceQuickActionSurfacesPulseAndKeepsAgeUpAvailable() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])
        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(element("finance-tab", in: app).waitForExistence(timeout: 5))
        element("finance-tab", in: app).tap()
        XCTAssertTrue(element("quick-action-cutSpending", in: app).waitForExistence(timeout: 3))
        element("quick-action-cutSpending", in: app).tap()
        let pulseAppeared = element("activity-pulse-banner", in: app).waitForExistence(timeout: 3)
        let actionMarkedDone = app.staticTexts["DONE"].waitForExistence(timeout: 1)
        XCTAssertTrue(pulseAppeared || actionMarkedDone)
        XCTAssertTrue(app.buttons["age-up-button"].exists)
    }

    @MainActor
    func testHistoryTabShowsSeededJournalEntry() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])
        enterPlannerShellIfNeeded(app)

        app.buttons["history-tab"].tap()
        XCTAssertTrue(app.otherElements["history-tab-content"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["You held onto work momentum and started looking promotable."].waitForExistence(timeout: 2))
    }

    @MainActor
    func testHomeUrgencyMoneyOpensCashflowDetail() throws {
        let app = launchApp(arguments: [
            "-debug-scenario", "adultCareerFlow"
        ])
        enterPlannerShellIfNeeded(app)

        XCTAssertTrue(element("home-urgency-money", in: app).waitForExistence(timeout: 3))
        element("home-urgency-money", in: app).tap()
        XCTAssertTrue(element("detail-sheet-financeCashflow", in: app).waitForExistence(timeout: 3))
        let done = app.navigationBars.buttons["Done"]
        if done.waitForExistence(timeout: 1) {
            done.tap()
        }
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 3) -> Bool {
        if element.waitForExistence(timeout: 1) {
            return true
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }

    private func launchApp(arguments: [String] = [], environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        let launchToken = UUID().uuidString
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments.append(contentsOf: arguments)
        app.launchEnvironment["ONELIFE_TEST_SAVE_DIR"] = (NSTemporaryDirectory() as NSString).appendingPathComponent("OneLifeUITests/\(launchToken)")
        app.launchEnvironment["ONELIFE_TEST_DEFAULTS_SUITE"] = "OneLifeUITests.\(launchToken)"
        app.launchEnvironment["ONELIFE_DISABLE_OPENING_EVENT"] = "1"
        app.launchEnvironment.merge(environment) { _, new in new }
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        return app
    }
}
