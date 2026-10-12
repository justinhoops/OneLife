import XCTest

final class OneLifeUITests: XCTestCase {
    private func startCustomLife(
        _ app: XCUIApplication,
        name: String = "Avery",
        origin: String? = nil
    ) {
        let custom = app.buttons["Custom"]
        XCTAssertTrue(custom.waitForExistence(timeout: 3))
        custom.tap()
        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        if nameField.frame.midY > app.frame.height * 0.55 {
            app.swipeUp()
        }
        nameField.tap()
        let focused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasKeyboardFocus == true"),
            object: nameField
        )
        if XCTWaiter.wait(for: [focused], timeout: 1) != .completed {
            nameField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        nameField.typeText(name)
        if let origin { app.buttons["Origin \(origin)"].tap() }
        let start = app.buttons["Start Custom Life"]
        for _ in 0..<4 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        start.tap()
    }

    private func resolvePendingEventIfPresent(_ app: XCUIApplication) {
        let choice = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "Event Choice ")
        ).firstMatch
        for _ in 0..<3 {
            guard choice.waitForExistence(timeout: 1) else { break }
            choice.tap()
        }
        let continueButton = app.buttons["Year Recap Continue"]
        if continueButton.waitForExistence(timeout: 1) { continueButton.tap() }
    }

    private func swipePresentedContentUp(_ app: XCUIApplication) {
        let lists = app.collectionViews
        if lists.count > 0 {
            let presentedList = lists.element(boundBy: lists.count - 1)
            presentedList.swipeUp()
        } else {
            app.swipeUp()
        }
    }

    private func swipePresentedContentDown(_ app: XCUIApplication) {
        let lists = app.collectionViews
        if lists.count > 0 {
            let presentedList = lists.element(boundBy: lists.count - 1)
            presentedList.swipeDown()
        } else {
            app.swipeDown()
        }
    }

    func testRandomPreviewRerollStartAndIdentityJourney() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()

        let start = app.buttons["Start This Life"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        let firstSeed = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Seed ")).firstMatch.label
        app.buttons["Reroll Life"].tap()
        let seedChanged = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", firstSeed),
            object: app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Seed ")).firstMatch
        )
        XCTAssertEqual(XCTWaiter.wait(for: [seedChanged], timeout: 3), .completed)
        start.tap()

        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 4))
        app.buttons["Menu"].tap()
        app.buttons["Identity"].tap()
        XCTAssertTrue(app.navigationBars["Identity"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Your personality"].exists)
        XCTAssertTrue(app.staticTexts["Identity Signature"].exists)
        XCTAssertTrue(app.staticTexts["Drive"].exists)
        let people = app.staticTexts["People"]
        for _ in 0..<3 where !people.exists { app.swipeUp() }
        XCTAssertTrue(people.exists)
    }

    func testCommittedRandomLifeSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        app.buttons["Start This Life"].tap()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 4))
        let committedName = app.navigationBars.firstMatch.identifier

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 4))
        XCTAssertEqual(app.navigationBars.firstMatch.identifier, committedName)
    }

    func testDashboardShowsCurrentLifeNarrative() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()

        XCTAssertTrue(app.buttons["Start This Life"].waitForExistence(timeout: 4))
        app.buttons["Start This Life"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["Current Life Narrative"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testPersonalityConditionAppearsInActionPreview() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestPartnerConfrontation"]
        app.launch()
        app.buttons["Domain Play"].tap()
        let party = app.buttons["Party"]
        XCTAssertTrue(party.waitForExistence(timeout: 3))
        party.press(forDuration: 0.7)
        XCTAssertTrue(app.navigationBars["Party"].waitForExistence(timeout: 3))
        let cause = app.staticTexts["Cautious partner"]
        for _ in 0..<3 where !cause.exists { app.swipeUp() }
        XCTAssertTrue(cause.waitForExistence(timeout: 3))
    }

    func testEconomyForecastAndWorkoutReview() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestEconomy", "-uiTestWorkout"]
        app.launch()
        app.buttons["Domain Cash"].tap()
        app.buttons["Household Glance Card"].tap()
        XCTAssertTrue(app.staticTexts["Monthly surplus / shortfall"].waitForExistence(timeout: 3))
        let negotiate = app.buttons["Economy recovery negotiateDebt"]
        for _ in 0..<8 where !negotiate.isHittable { swipePresentedContentUp(app) }
        XCTAssertTrue(negotiate.isHittable)
        negotiate.tap()
        let accept = app.buttons["Event Choice accept"]
        XCTAssertTrue(accept.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Initial debt payment:")).firstMatch.exists)
        app.buttons["Event Choice decline"].tap()
        XCTAssertTrue(app.buttons["Domain Cash"].waitForExistence(timeout: 3))
    }

    func testEconomyConversionExplainsNewTerms() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestEconomy", "-uiTestConversion"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Economy Updated"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Expected annual balance"].exists)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Domain Cash"].waitForExistence(timeout: 3))
        app.buttons["Domain Cash"].tap()
        app.buttons["Household Glance Card"].tap()
        XCTAssertTrue(app.navigationBars["Household Ledger"].waitForExistence(timeout: 3))
    }

    func testEssentialGlanceCardsAndDeepLedger() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        startCustomLife(app)
        app.buttons["Cash"].tap()
        XCTAssertTrue(app.buttons["Work Glance Card"].waitForExistence(timeout: 3))
        let household = app.buttons["Household Glance Card"]
        XCTAssertTrue(household.exists)
        household.tap()
        XCTAssertTrue(app.navigationBars["Household Ledger"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Annual surplus / shortfall"].exists)
        app.buttons["Done"].tap()
        app.buttons["Love"].tap()
        XCTAssertTrue(app.buttons["Partner Glance Card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Family Glance Card"].exists)
        let people = app.buttons["People Glance Card"]
        XCTAssertTrue(people.exists)
        people.tap()
        XCTAssertTrue(app.navigationBars["People"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["People Detail"].exists)
    }

    func testContinuityCardKeepsPersistentPressureAtAGlance() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestContinuity"]
        app.launch()

        let card = app.descendants(matching: .any)["Continuity Card"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Still shaping this life"].exists)
        XCTAssertTrue(app.staticTexts["The layoff still shapes your choices"].exists)
        XCTAssertTrue(app.staticTexts["Money · active · 3y window"].exists)
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testPlaytestModeRecordsAnnotationAndOffersExport() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-playtest", "-uiTestEmptyPlaytestCohort"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["Playtest Cohort Target"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Balanced · Grind"].exists)
        XCTAssertTrue(app.buttons["Start Custom Life"].exists)
        startCustomLife(app)
        resolvePendingEventIfPresent(app)
        XCTAssertTrue(app.buttons["Chase grades"].waitForExistence(timeout: 3))
        app.buttons["Chase grades"].tap()
        resolvePendingEventIfPresent(app)

        app.buttons["Menu"].tap()
        let notes = app.buttons["Playtest Notes Menu Item"]
        XCTAssertTrue(notes.waitForExistence(timeout: 3))
        notes.tap()
        XCTAssertTrue(app.navigationBars["Playtest Notes"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["Recorded Playtest Moments"].exists)
        let recordedStyle = app.descendants(matching: .any)["Recorded Playtest Style Value"]
        XCTAssertTrue(recordedStyle.exists)
        XCTAssertTrue(recordedStyle.label.contains("Grind"))
        let saveObservation = app.buttons["Save Playtest Observation"]
        for _ in 0..<2 where !saveObservation.isHittable { swipePresentedContentUp(app) }
        for _ in 0..<3 where !saveObservation.isHittable { swipePresentedContentDown(app) }
        XCTAssertTrue(saveObservation.isHittable)
        saveObservation.tap()
        XCTAssertTrue(app.descendants(matching: .any)["Export Playtest Report"].waitForExistence(timeout: 3))
    }

    func testAccessibilityTextKeepsCoreControlsReachable() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestReset",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        startCustomLife(app)

        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
        XCTAssertTrue(app.buttons["Domain Cash"].isHittable)
        XCTAssertTrue(app.buttons["Domain Love"].isHittable)
        XCTAssertTrue(app.buttons["Domain Play"].isHittable)
    }

    func testReduceMotionSuppressesFloatingDeltasOnSmallScreen() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestReset",
            "-uiTestPostSchool",
            "-uiTestReduceMotion",
            "-uiTestMotionDiagnostics"
        ]
        app.launch()

        let diagnostics = app.descendants(matching: .any)["Motion Diagnostics"]
        XCTAssertTrue(diagnostics.waitForExistence(timeout: 3))
        XCTAssertEqual(diagnostics.value as? String, "Reduced motion")
        let floatingLayer = app.descendants(matching: .any)["Floating Delta Layer"]
        XCTAssertTrue(floatingLayer.waitForExistence(timeout: 3))
        XCTAssertEqual(floatingLayer.value as? String, "0")

        let action = app.buttons["Network"]
        XCTAssertTrue(action.waitForExistence(timeout: 3))
        action.tap()

        XCTAssertEqual(app.descendants(matching: .any)["Floating Delta Layer"].value as? String, "0")
    }

    func testLateLifePressureKeepsGlanceSummaryAndControlsVisibleOnSmallScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestLateLifeDensity"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Age 72"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["Stat Island"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Stage Strip"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["What Matters"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Mortality Pressure"].exists)

        let bottomNavigationTop = app.buttons["Domain Cash"].frame.minY
        let expectedPressures = [
            "Mortality Vulnerable → Seek care",
            "Runway → Work a shift",
            "Body → Rest"
        ]
        for label in expectedPressures {
            let pressure = app.staticTexts[label]
            XCTAssertTrue(pressure.exists, "Missing late-life pressure: \(label)")
            XCTAssertLessThan(
                pressure.frame.maxY,
                bottomNavigationTop,
                "Late-life pressure is outside the initial glance: \(label)"
            )
        }

        XCTAssertTrue(app.buttons["Age Up"].isHittable)
        XCTAssertTrue(app.buttons["Domain Cash"].isHittable)
        XCTAssertTrue(app.buttons["Domain Love"].isHittable)
        XCTAssertTrue(app.buttons["Domain Play"].isHittable)
    }

    func testLandscapeKeepsLateLifeGlanceAndThumbControlsReachable() {
        let device = XCUIDevice.shared
        device.orientation = .landscapeLeft
        addTeardownBlock { device.orientation = .portrait }

        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestLateLifeDensity"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Age 72"].waitForExistence(timeout: 3))
        XCTAssertGreaterThan(app.frame.width, app.frame.height)
        XCTAssertTrue(app.descendants(matching: .any)["Stat Island"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["What Matters"].exists)
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
        XCTAssertTrue(app.buttons["Domain School"].isHittable)
        XCTAssertTrue(app.buttons["Domain Cash"].isHittable)
        XCTAssertTrue(app.buttons["Domain Love"].isHittable)
        XCTAssertTrue(app.buttons["Domain Play"].isHittable)

        app.buttons["Domain Cash"].tap()
        XCTAssertTrue(app.buttons["Work Glance Card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testLockedActionDisclosesRequirement() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestHighSchoolIdentity"]
        app.launch()
        let people = app.buttons["Find your people"]
        XCTAssertTrue(people.waitForExistence(timeout: 3))
        let locked = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS %@ AND value CONTAINS %@", "Locked", "focus is already set"),
            object: people
        )
        XCTAssertEqual(XCTWaiter.wait(for: [locked], timeout: 3), .completed)
    }

    func testStartLifeTakeActionAndAgeUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        startCustomLife(app)
        XCTAssertTrue(app.descendants(matching: .any)["High School Overview"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Chase grades"].exists)
        XCTAssertTrue(app.buttons["Domain Cash"].exists)
        XCTAssertTrue(app.buttons["Domain Love"].exists)
        XCTAssertTrue(app.buttons["Domain Play"].exists)
        app.buttons["Chase grades"].tap()
        if app.buttons["Outcome Continue"].waitForExistence(timeout: 3) { app.buttons["Outcome Continue"].tap() }
        app.buttons["Age Up"].tap()
    }

    func testHighSchoolIdentityCardStaysCompact() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestHighSchoolIdentity"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["This Year at School"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Junior · Committing to an activity"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Friend ·'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Service group · Committed"].exists)
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testAcademicPresetStartsDashboard() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        startCustomLife(app, origin: "Academic")
        XCTAssertTrue(app.buttons["Chase grades"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testPartnerConfrontationIsMajorAndResolvesBackToPlay() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestPartnerConfrontation"]
        app.launch()

        XCTAssertTrue(app.buttons["Domain Love"].waitForExistence(timeout: 3))
        app.buttons["Domain Love"].tap()
        XCTAssertTrue(app.buttons["Partner Glance Card"].waitForExistence(timeout: 3))

        app.buttons["Domain Cash"].tap()
        XCTAssertTrue(app.buttons["Work a shift"].waitForExistence(timeout: 3))
        app.buttons["Work a shift"].tap()
        if app.buttons["Outcome Continue"].waitForExistence(timeout: 3) { app.buttons["Outcome Continue"].tap() }
        app.buttons["Age Up"].tap()

        XCTAssertTrue(app.staticTexts["Your Partner Needs You Present"].waitForExistence(timeout: 4))
        let dismiss = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dismiss it")).firstMatch
        XCTAssertTrue(dismiss.waitForExistence(timeout: 3))
        dismiss.tap()

        XCTAssertTrue(app.descendants(matching: .any)["Year Summary"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Year Recap Continue"].isHittable)
        app.buttons["Year Recap Continue"].tap()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Age Up"].isEnabled)
    }

    /// Post-school Skills tab offers chapter actions (Codex progressive disclosure).
    func testPostSchoolSkillsTabShowsChapterActions() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestPostSchool"]
        app.launch()

        XCTAssertTrue(app.buttons["Domain School"].waitForExistence(timeout: 3))
        app.buttons["Domain School"].tap()
        XCTAssertTrue(app.buttons["Network"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Side hustle"].exists)
        XCTAssertFalse(app.buttons["Study"].exists)
        app.buttons["Network"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Life Moment Popup"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Outcome Continue"].exists)
    }

    func testLaunchSchoolFoundationStaysCompactBeforeBuild() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestSchoolLegacy"]
        app.launch()

        XCTAssertTrue(app.buttons["Domain School"].waitForExistence(timeout: 3))
        app.buttons["Domain School"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["High School Foundation"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Practical training"].exists)
        XCTAssertTrue(app.staticTexts["Early influence · 1y"].exists)
        XCTAssertFalse(app.navigationBars["School Ledger"].exists)
    }

    func testGraduationOfferEnrollmentAndFieldJourney() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestCollegeOffers"]
        app.launch()

        XCTAssertTrue(app.staticTexts["High School Is Behind You"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["Life Moment Popup"].exists)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Take the scholarship")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Choose What You Will Study"].waitForExistence(timeout: 3))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Applied & technical")).firstMatch.tap()
        if app.buttons["Year Recap Continue"].waitForExistence(timeout: 3) { app.buttons["Year Recap Continue"].tap() }
        XCTAssertTrue(app.buttons["Domain School"].waitForExistence(timeout: 3))
        app.buttons["Domain School"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["College Foundation"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Scholarship university"].exists)
        XCTAssertTrue(app.staticTexts["2/12"].exists)
    }

    func testCollegeFoundationAndTransferJourney() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestCollege"]
        app.launch()
        app.buttons["Domain School"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["College Foundation"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["$4500/yr debt"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["High School Foundation"].exists)

        app.terminate()
        app.launchArguments = ["-uiTestReset", "-uiTestCollegeTransfer"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Your Associate Degree Is Complete"].waitForExistence(timeout: 4))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Transfer every credit")).firstMatch.tap()
        app.buttons["Domain School"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["College Foundation"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Public university"].exists)
        XCTAssertTrue(app.staticTexts["8/12"].exists)
    }

    func testAdultEducationRecoveryStaysCompact() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestEducationRecovery"]
        app.launch()

        XCTAssertTrue(app.buttons["Domain School"].waitForExistence(timeout: 3))
        app.buttons["Domain School"].tap()
        XCTAssertTrue(app.buttons["Return to education"].waitForExistence(timeout: 3))
        app.buttons["Return to education"].tap()
        XCTAssertTrue(app.staticTexts["Your Education Record Opens Again"].waitForExistence(timeout: 3))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Earn a technical certificate")).firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["Education Recovery Foundation"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Technical certificate"].exists)
        XCTAssertTrue(app.staticTexts["0/6"].exists)
        XCTAssertFalse(app.navigationBars["School Ledger"].exists)
    }

    func testWorldHeadlineAppearsOnlyInYearSummary() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestWorldNews"]
        app.launch()

        let headline = app.staticTexts["Price Pressure Finally Begins Easing"]
        for _ in 0..<3 where !headline.exists { app.swipeUp() }
        XCTAssertTrue(headline.waitForExistence(timeout: 3))
        XCTAssertFalse(app.navigationBars["Price Pressure Finally Begins Easing"].exists)
        XCTAssertTrue(app.buttons["Year Recap Continue"].isHittable)
        app.buttons["Year Recap Continue"].tap()
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testQuietYearUsesCompactRecapAndReturnsToDashboard() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestQuietRecap"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Another Year"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Quiet year"].exists)
        XCTAssertTrue(app.buttons["Year Recap Continue"].isHittable)
        app.buttons["Year Recap Continue"].tap()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testYearlyDecisionCannotDismissAndTransitionsToRecapInPlace() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestYearlyDecisionFlow"]
        app.launch()

        let popup = app.descendants(matching: .any)["Life Moment Popup"]
        XCTAssertTrue(popup.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["THIS YEAR"].exists)
        app.swipeDown()
        XCTAssertTrue(popup.exists)

        app.buttons["Event Choice accept"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Year Summary"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Cash +30"].exists)
        XCTAssertTrue(app.staticTexts["Health -6"].exists)
        XCTAssertTrue(app.buttons["Year Recap Continue"].isHittable)
        app.buttons["Year Recap Continue"].tap()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
    }

    func testTwoYearlyChoicesResolveInOneCenteredSequence() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestTwoYearlyChoices"]
        app.launch()

        let popup = app.descendants(matching: .any)["Life Moment Popup"]
        XCTAssertTrue(popup.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Work Asked For Another Sacrifice"].exists)
        app.buttons["Event Choice accept"].tap()
        XCTAssertTrue(app.staticTexts["A Friend Offered Another Way"].waitForExistence(timeout: 3))
        XCTAssertTrue(popup.exists)
        app.buttons["Event Choice accept"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Year Summary"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["A Friend Offered Another Way"].exists)
        app.buttons["Year Recap Continue"].tap()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
    }

    func testSelectedPartnerSuggestionUsesCenteredOutcomeAndAccessibleControls() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestReset", "-uiTestPartnerConfrontation",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        app.buttons["Domain Love"].tap()
        let focus = app.buttons["Person Focus"]
        XCTAssertTrue(focus.waitForExistence(timeout: 3))
        focus.tap()
        app.buttons["Morgan"].tap()
        let suggestion = app.buttons["Suggested Action context:makeAmends"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 3))
        XCTAssertTrue(suggestion.isHittable)
        suggestion.tap()
        XCTAssertTrue(app.descendants(matching: .any)["Life Moment Popup"].waitForExistence(timeout: 3))
        let dismiss = app.buttons["Outcome Continue"]
        XCTAssertTrue(dismiss.isHittable)
        XCTAssertFalse(dismiss.label.isEmpty)
        dismiss.tap()
        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
    }

    func testWorldHeadlineRemainsReachableAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestReset",
            "-uiTestWorldNews",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        let headline = app.staticTexts["Price Pressure Finally Begins Easing"]
        for _ in 0..<5 where !headline.exists { app.swipeUp() }
        XCTAssertTrue(headline.waitForExistence(timeout: 3))
        for _ in 0..<5 where !app.buttons["Year Recap Continue"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Year Recap Continue"].isHittable)
        app.buttons["Year Recap Continue"].tap()
        XCTAssertTrue(app.buttons["Age Up"].isHittable)
    }

    func testPublicHealthHeadlineAndAdjustedCarePreview() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestPublicHealth"]
        app.launch()

        let headline = app.staticTexts["A Public-Health Outbreak Escalates"]
        for _ in 0..<3 where !headline.exists { app.swipeUp() }
        XCTAssertTrue(headline.waitForExistence(timeout: 3))
        app.buttons["Year Recap Continue"].tap()

        app.buttons["Health actions"].tap()
        let care = app.buttons["Seek care"]
        XCTAssertTrue(care.waitForExistence(timeout: 3))
        care.press(forDuration: 1.0)
        XCTAssertTrue(app.navigationBars["Seek care"].waitForExistence(timeout: 3))
        let projected = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Projected care cost")).firstMatch
        let world = app.staticTexts["Current world"]
        for _ in 0..<4 where !projected.exists || !world.exists { app.swipeUp() }
        XCTAssertTrue(projected.exists)
        XCTAssertTrue(world.exists)
    }

    func testPublicHealthCarePreviewAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestReset", "-uiTestPublicHealth",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        let continueButton = app.buttons["Year Recap Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3))
        continueButton.tap()
        app.buttons["Health actions"].tap()
        let care = app.buttons["Seek care"]
        XCTAssertTrue(care.waitForExistence(timeout: 3))
        care.press(forDuration: 1.0)
        let projected = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Projected care cost")).firstMatch
        let previewList = app.collectionViews.element(boundBy: max(0, app.collectionViews.count - 1))
        for _ in 0..<3 where !projected.exists { previewList.swipeUp() }
        XCTAssertTrue(projected.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Done"].isHittable)
    }

    func testAssetShopSupportsDuplicatesHousesSalesAndGunLock() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestAssets"]
        app.launch()

        app.buttons["Domain Cash"].tap()
        let assets = app.buttons["Assets Glance Card"]
        XCTAssertTrue(assets.waitForExistence(timeout: 3))
        assets.tap()
        XCTAssertTrue(app.navigationBars["Assets"].waitForExistence(timeout: 3))

        let buyCompact = app.buttons["Buy Older hatchback"]
        for _ in 0..<3 where !buyCompact.isHittable { app.swipeUp() }
        XCTAssertTrue(buyCompact.waitForExistence(timeout: 3))
        buyCompact.tap()
        XCTAssertTrue(app.buttons["Confirm purchase"].waitForExistence(timeout: 2))
        app.buttons["Confirm purchase"].tap()
        buyCompact.tap()
        app.buttons["Confirm purchase"].tap()
        let ownedTwo = app.staticTexts["Owned · 2"]
        for _ in 0..<4 where !ownedTwo.exists { app.swipeUp() }
        XCTAssertTrue(ownedTwo.waitForExistence(timeout: 3))

        for _ in 0..<4 where !app.buttons["Asset Category Houses"].isHittable { app.swipeDown() }
        app.buttons["Asset Category Houses"].tap()
        let starter = app.buttons["Buy Cedar Court Condo"]
        XCTAssertTrue(starter.waitForExistence(timeout: 3))
        starter.tap()
        app.buttons["Confirm purchase"].tap()
        let primary = app.staticTexts["Primary"]
        for _ in 0..<5 where !primary.exists { app.swipeUp() }
        XCTAssertTrue(primary.waitForExistence(timeout: 3))

        for _ in 0..<5 where !app.buttons["Asset Category Guns"].isHittable { app.swipeDown() }
        app.buttons["Asset Category Guns"].tap()
        let ageLock = app.staticTexts["Available at age 21"]
        for _ in 0..<3 where !ageLock.exists { app.swipeUp() }
        XCTAssertTrue(ageLock.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Buy Sporting handgun"].isEnabled)

        for _ in 0..<4 where !app.buttons["Asset Category Vehicles"].isHittable { app.swipeDown() }
        app.buttons["Asset Category Vehicles"].tap()
        let sale = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "Sell Older hatchback")).firstMatch
        for _ in 0..<6 where !sale.isHittable { app.swipeUp() }
        XCTAssertTrue(sale.waitForExistence(timeout: 3))
        sale.tap()
        app.buttons["Confirm sale"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Asset Transaction Feedback"].waitForExistence(timeout: 3))
    }

    func testAssetShopRemainsUsableAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestReset", "-uiTestAssets",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        app.buttons["Domain Cash"].tap()
        let assets = app.buttons["Assets Glance Card"]
        for _ in 0..<3 where !assets.isHittable { app.swipeUp() }
        XCTAssertTrue(assets.isHittable)
        assets.tap()
        let categoryMenu = app.buttons["Asset Category Menu"]
        for _ in 0..<4 where !categoryMenu.isHittable { app.swipeUp() }
        XCTAssertTrue(categoryMenu.isHittable)
        let vehicleMenu = app.buttons["Vehicle Class Menu"]
        for _ in 0..<3 where !vehicleMenu.isHittable { app.swipeUp() }
        XCTAssertTrue(vehicleMenu.isHittable)
        vehicleMenu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let boatsChoice = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Boats & Yachts"))
            .firstMatch
        if !boatsChoice.waitForExistence(timeout: 2) {
            vehicleMenu.tap()
        }
        XCTAssertTrue(boatsChoice.waitForExistence(timeout: 3))
        boatsChoice.tap()
        let buyCabinCruiser = app.buttons["Buy Cabin cruiser"]
        for _ in 0..<4 where !buyCabinCruiser.isHittable { swipePresentedContentUp(app) }
        for _ in 0..<4 where !buyCabinCruiser.isHittable { swipePresentedContentDown(app) }
        XCTAssertTrue(buyCabinCruiser.isHittable)
        buyCabinCruiser.tap()
        app.buttons["Confirm purchase"].tap()
        XCTAssertTrue(app.buttons["Confirm purchase"].waitForNonExistence(timeout: 3))
        let renameBoat = app.buttons["Rename Vehicle 1"]
        for _ in 0..<14 where !renameBoat.isHittable { swipePresentedContentUp(app) }
        XCTAssertTrue(renameBoat.isHittable)
        renameBoat.tap()
        let boatName = app.textFields["Vehicle Name Field"]
        XCTAssertTrue(boatName.waitForExistence(timeout: 3))
        boatName.tap()
        boatName.typeText("Sea Star")
        app.buttons["Save Vehicle Name"].tap()
        XCTAssertTrue(app.staticTexts["Sea Star"].waitForExistence(timeout: 3))
        for _ in 0..<6 where !categoryMenu.isHittable { app.swipeDown() }
        XCTAssertTrue(categoryMenu.isHittable)
        categoryMenu.tap()
        app.buttons["Jewelry"].tap()
        let buy = app.buttons["Buy Gold watch"]
        for _ in 0..<4 where !buy.isHittable { swipePresentedContentUp(app) }
        for _ in 0..<4 where !buy.isHittable { swipePresentedContentDown(app) }
        XCTAssertTrue(buy.isHittable)
        buy.tap()
        XCTAssertTrue(app.buttons["Confirm purchase"].waitForExistence(timeout: 2))
        app.buttons["Confirm purchase"].tap()
        XCTAssertTrue(app.navigationBars["Assets"].exists)

        for _ in 0..<6 where !categoryMenu.isHittable { app.swipeDown() }
        XCTAssertTrue(categoryMenu.isHittable)
        categoryMenu.tap()
        app.buttons["Houses"].tap()
        let buyHouse = app.buttons["Buy Maple Street House"]
        for _ in 0..<5 where !buyHouse.isHittable { swipePresentedContentUp(app) }
        for _ in 0..<4 where !buyHouse.isHittable { swipePresentedContentDown(app) }
        XCTAssertTrue(buyHouse.isHittable)
        buyHouse.tap()
        app.buttons["Confirm purchase"].tap()
        let manage = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "Manage Property")).firstMatch
        for _ in 0..<12 where !manage.isHittable { swipePresentedContentUp(app) }
        XCTAssertTrue(manage.isHittable)
        manage.tap()
        let amenities = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "Manage Amenities")).firstMatch
        for _ in 0..<8 where !amenities.isHittable { swipePresentedContentUp(app) }
        XCTAssertTrue(amenities.isHittable)
        amenities.tap()
        let installAmenity = app.buttons["Install swimmingPool"]
        for _ in 0..<5 where !installAmenity.isHittable { swipePresentedContentUp(app) }
        for _ in 0..<4 where !installAmenity.isHittable { swipePresentedContentDown(app) }
        XCTAssertTrue(installAmenity.isHittable)
        installAmenity.tap()
        XCTAssertTrue(app.buttons["Confirm amenity"].waitForExistence(timeout: 2))
        app.buttons["Confirm amenity"].tap()
        let installed = app.staticTexts["Installed · 1"]
        for _ in 0..<6 where !installed.exists { swipePresentedContentDown(app) }
        XCTAssertTrue(installed.waitForExistence(timeout: 3))
        let amenitiesBar = app.navigationBars["Amenities"]
        XCTAssertTrue(amenitiesBar.exists)
        XCTAssertTrue(amenitiesBar.buttons.firstMatch.isHittable)
    }

    func testPropertyAmenitiesUpdateValueUpkeepAndPersistInOwnedProperty() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestAssets"]
        app.launch()

        app.buttons["Domain Cash"].tap()
        app.buttons["Assets Glance Card"].tap()
        app.buttons["Asset Category Houses"].tap()
        let buyHouse = app.buttons["Buy Maple Street House"]
        for _ in 0..<4 where !buyHouse.isHittable { app.swipeUp() }
        XCTAssertTrue(buyHouse.isHittable)
        buyHouse.tap()
        app.buttons["Confirm purchase"].tap()

        let manage = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "Manage Property")).firstMatch
        for _ in 0..<8 where !manage.isHittable { app.swipeUp() }
        XCTAssertTrue(manage.isHittable)
        manage.tap()
        XCTAssertTrue(app.navigationBars["Maple Street House"].waitForExistence(timeout: 3))
        let amenities = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "Manage Amenities")).firstMatch
        for _ in 0..<8 where !amenities.isHittable { app.swipeUp() }
        XCTAssertTrue(amenities.isHittable)
        amenities.tap()
        let installGym = app.buttons["Install homeGym"]
        for _ in 0..<4 where !installGym.isHittable { app.swipeUp() }
        XCTAssertTrue(installGym.isHittable)
        installGym.tap()
        app.buttons["Confirm amenity"].tap()

        let installed = app.staticTexts["Installed · 1"]
        for _ in 0..<5 where !installed.exists { app.swipeDown() }
        XCTAssertTrue(installed.waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["Property Amenity Improvement Value"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Property Amenity Upkeep"].exists)
        XCTAssertFalse(app.buttons["Install homeGym"].isEnabled)
    }

    func testRealEstatePortfolioListsSecondaryPropertyAndShowsManagement() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestAssets"]
        app.launch()

        app.buttons["Domain Cash"].tap()
        app.buttons["Assets Glance Card"].tap()
        app.buttons["Asset Category Houses"].tap()
        for name in ["Juniper Row Townhome", "Maple Street House"] {
            let buy = app.buttons["Buy \(name)"]
            for _ in 0..<8 where !buy.isHittable { swipePresentedContentDown(app) }
            for _ in 0..<8 where !buy.isHittable { swipePresentedContentUp(app) }
            XCTAssertTrue(buy.isHittable)
            buy.tap()
            XCTAssertTrue(app.buttons["Confirm purchase"].waitForExistence(timeout: 2))
            app.buttons["Confirm purchase"].tap()
        }

        let manage = app.buttons["Manage Property 2"]
        for _ in 0..<12 where !manage.isHittable { app.swipeUp() }
        XCTAssertTrue(manage.isHittable)
        manage.tap()
        XCTAssertTrue(app.navigationBars["Maple Street House"].waitForExistence(timeout: 3))
        let list = app.buttons["List Property for Rent"]
        for _ in 0..<5 where !list.isHittable { app.swipeUp() }
        XCTAssertTrue(list.isHittable)
        list.tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Rental"].waitForExistence(timeout: 3))
        let withdraw = app.buttons["Withdraw Rental Listing"]
        for _ in 0..<5 where !withdraw.isHittable { app.swipeUp() }
        XCTAssertTrue(withdraw.isHittable)
        let amenities = app.buttons["Manage Amenities 2"]
        for _ in 0..<8 where !amenities.isHittable { app.swipeUp() }
        XCTAssertTrue(amenities.isHittable)
    }

    func testVehicleStoreBrowsesAircraftAndBoatsWithOwnershipAndSale() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestAssets", "-uiTestVehicles"]
        app.launch()

        app.buttons["Domain Cash"].tap()
        app.buttons["Assets Glance Card"].tap()
        let classMenu = app.buttons["Vehicle Class Menu"]
        XCTAssertTrue(classMenu.waitForExistence(timeout: 3))

        classMenu.tap()
        app.buttons["Helicopters"].tap()
        let buyHelicopter = app.buttons["Buy Utility helicopter"]
        XCTAssertTrue(buyHelicopter.waitForExistence(timeout: 3))
        buyHelicopter.tap()
        app.buttons["Confirm purchase"].tap()

        classMenu.tap()
        app.buttons["Planes"].tap()
        let buyPlane = app.buttons["Buy Light sport aircraft"]
        XCTAssertTrue(buyPlane.waitForExistence(timeout: 3))
        buyPlane.tap()
        app.buttons["Confirm purchase"].tap()

        classMenu.tap()
        app.buttons["Boats & Yachts"].tap()
        let buyBoat = app.buttons["Buy Fishing boat"]
        XCTAssertTrue(buyBoat.waitForExistence(timeout: 3))
        buyBoat.tap()
        app.buttons["Confirm purchase"].tap()
        XCTAssertTrue(app.buttons["Confirm purchase"].waitForNonExistence(timeout: 3))
        let owned = app.staticTexts["Owned · 1"]
        for _ in 0..<6 where !owned.exists { app.swipeUp() }
        XCTAssertTrue(owned.waitForExistence(timeout: 3))
        let rename = app.buttons["Rename Vehicle 3"]
        for _ in 0..<4 where !rename.isHittable { app.swipeUp() }
        XCTAssertTrue(rename.isHittable)
        rename.tap()
        let nameField = app.textFields["Vehicle Name Field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Sea Star")
        app.buttons["Save Vehicle Name"].tap()
        XCTAssertTrue(app.staticTexts["Sea Star"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Originally Fishing boat"].exists)
        let sell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "Sell Sea Star")).firstMatch
        for _ in 0..<4 where !sell.isHittable { app.swipeUp() }
        XCTAssertTrue(sell.isHittable)
        sell.tap()
        app.buttons["Confirm sale"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Asset Transaction Feedback"].waitForExistence(timeout: 3))
    }

    func testCarGroupsSupportManufacturerFreePurchaseRenameAndReset() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestAssets", "-uiTestVehicles"]
        app.launch()

        app.buttons["Domain Cash"].tap()
        app.buttons["Assets Glance Card"].tap()
        let everydayCar = app.buttons["Buy Older hatchback"]
        for _ in 0..<3 where !everydayCar.isHittable { app.swipeUp() }
        XCTAssertTrue(everydayCar.waitForExistence(timeout: 3))
        let performance = app.buttons["Car Group Performance"]
        for _ in 0..<3 where !performance.isHittable { app.swipeDown() }
        XCTAssertTrue(performance.isHittable)
        performance.tap()

        let roadster = app.buttons["Buy Used roadster"]
        for _ in 0..<3 where !roadster.isHittable { app.swipeUp() }
        XCTAssertTrue(roadster.waitForExistence(timeout: 3))
        roadster.tap()
        app.buttons["Confirm purchase"].tap()
        XCTAssertTrue(app.buttons["Confirm purchase"].waitForNonExistence(timeout: 3))
        let rename = app.buttons["Rename Vehicle 1"]
        for _ in 0..<6 where !rename.isHittable { app.swipeUp() }
        XCTAssertTrue(rename.waitForExistence(timeout: 3))
        rename.tap()

        let field = app.textFields["Vehicle Name Field"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("Bluebird")
        app.buttons["Save Vehicle Name"].tap()
        XCTAssertTrue(app.staticTexts["Bluebird"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Originally Used roadster"].exists)

        app.buttons["Rename Vehicle 1"].tap()
        XCTAssertTrue(app.buttons["Reset Vehicle Name"].waitForExistence(timeout: 3))
        app.buttons["Reset Vehicle Name"].tap()
        XCTAssertTrue(app.staticTexts["Used roadster"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Originally Used roadster"].exists)
    }

    func testIllegalGunMarketAddsHeatAndSupportsAbstractUpgrades() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestAssets", "-uiTestAssetGuns"]
        app.launch()

        app.buttons["Domain Cash"].tap()
        app.buttons["Assets Glance Card"].tap()
        app.buttons["Asset Category Guns"].tap()
        app.buttons["Illegal market"].tap()
        let riskLine = app.staticTexts["Uncommon · Illegal market · heat +8"]
        for _ in 0..<3 where !riskLine.exists { app.swipeUp() }
        XCTAssertTrue(riskLine.waitForExistence(timeout: 3))

        let buyIllegal = app.buttons["Buy Unregistered handgun"]
        for _ in 0..<2 where !buyIllegal.isHittable { app.swipeUp() }
        XCTAssertTrue(buyIllegal.isHittable)
        buyIllegal.tap()
        app.buttons["Confirm purchase"].tap()

        let switchUpgrade = app.buttons.matching(NSPredicate(format: "identifier CONTAINS %@", "conversionSwitch")).firstMatch
        for _ in 0..<8 where !switchUpgrade.isHittable { app.swipeUp() }
        XCTAssertTrue(switchUpgrade.isHittable)
        switchUpgrade.tap()
        app.buttons["Confirm upgrade"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Conversion switch")).firstMatch.waitForExistence(timeout: 3))
    }

    /// Death → life review → New Life returns to creation (full ending loop).
    func testDeathReviewAndNewLife() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset", "-uiTestForceEnding", "-playtest"]
        app.launch()

        XCTAssertTrue(app.buttons["Age Up"].waitForExistence(timeout: 3))
        app.buttons["Age Up"].tap()

        // Stage/milestone sheets may appear; clear one choice if present.
        let faceChapter = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Face this chapter")).firstMatch
        if faceChapter.waitForExistence(timeout: 2) {
            faceChapter.tap()
        }
        let continueBtn = app.buttons["Continue"]
        if continueBtn.waitForExistence(timeout: 1) {
            continueBtn.tap()
        }

        // If still alive, age up again toward hard max / mortality.
        if app.buttons["Age Up"].waitForExistence(timeout: 2), app.buttons["Age Up"].isEnabled {
            app.buttons["Age Up"].tap()
            if faceChapter.waitForExistence(timeout: 1) { faceChapter.tap() }
            if continueBtn.waitForExistence(timeout: 1) { continueBtn.tap() }
        }

        let newLife = app.buttons["New Life"]
        XCTAssertTrue(newLife.waitForExistence(timeout: 6))
        let identitySection = app.staticTexts["Personality & world"]
        let identityLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Started ")).firstMatch
        for _ in 0..<5 where !identitySection.exists || !identityLine.exists { app.swipeUp() }
        XCTAssertTrue(identitySection.exists)
        XCTAssertTrue(identityLine.exists)

        let explanation = app.textFields["Outcome Explanation"]
        for _ in 0..<8 where !explanation.isHittable { app.swipeUp() }
        XCTAssertTrue(explanation.isHittable)
        explanation.tap()
        explanation.typeText("Health pressure shaped the ending.")
        let keyboardDone = app.keyboards.buttons["Done"]
        if keyboardDone.waitForExistence(timeout: 1) { keyboardDone.tap() }
        let saveOutcome = app.buttons["Save Outcome Check"]
        for _ in 0..<5 where !saveOutcome.isHittable { swipePresentedContentUp(app) }
        XCTAssertTrue(saveOutcome.isHittable)
        saveOutcome.tap()
        XCTAssertTrue(app.buttons["Save Outcome Check"].exists)
        newLife.tap()

        XCTAssertTrue(app.buttons["Start Custom Life"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["Playtest Cohort Target"].exists)
        XCTAssertTrue(app.buttons["Custom"].exists)
    }
}
