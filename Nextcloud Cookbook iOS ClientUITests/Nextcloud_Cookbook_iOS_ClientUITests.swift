//
//  Nextcloud_Cookbook_iOS_ClientUITests.swift
//  Nextcloud Cookbook iOS ClientUITests
//
//  Created by Vincent Meilinger on 06.09.23.
//

import XCTest

final class Nextcloud_Cookbook_iOS_ClientUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// TEMPORARY: reproduction of GitHub issues #36, #35, #28. Remove before committing.
final class IssueReproTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
        app.launch()
    }

    private func log(_ s: String) { XCTContext.runActivity(named: "PROBE: \(s)") { _ in } }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    static let recipeName = "Scroll Long Recipe"

    /// Opens the long test recipe, creating it the first time.
    private func openLongRecipe() {
        let newButton = app.buttons["New Recipe"].firstMatch
        XCTAssertTrue(newButton.waitForExistence(timeout: 10))
        let local = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Local'")).firstMatch
        if local.waitForExistence(timeout: 3) {
            local.tap()
            let cell = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", Self.recipeName)).firstMatch
            if cell.waitForExistence(timeout: 5) {
                cell.tap()
                XCTAssertTrue(app.staticTexts[Self.recipeName].waitForExistence(timeout: 10))
                return
            }
            app.navigationBars.buttons.firstMatch.tap()
        }
        _ = createLongRecipe()
    }

    /// Creates a local recipe with many ingredients (with markdown headers) and steps; returns its name.
    private func createLongRecipe() -> String {
        let name = Self.recipeName
        let newButton = app.buttons["New Recipe"].firstMatch
        XCTAssertTrue(newButton.waitForExistence(timeout: 10))
        newButton.tap()

        let nameField = app.textFields["Recipe Name"].firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)

        var ingredients: [String] = []
        for i in 1...105 {
            if i % 15 == 1 { ingredients.append("## Variation \((i / 15) + 1)") }
            else { ingredients.append("Ing \(i) flour \(i * 10) g") }
        }
        let addIngredient = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Add ingredient'")).firstMatch
        for _ in 0..<6 where !addIngredient.isHittable { app.swipeUp() }
        addIngredient.tap()
        addIngredient.typeText(ingredients.joined(separator: "\n") + "\n")

        let addStep = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Add step'")).firstMatch
        for _ in 0..<60 where !addStep.isHittable { app.swipeUp() }
        addStep.tap()
        let steps = (1...40).map { "Step \($0) mix everything carefully and wait until the dough is smooth and shiny" }
        addStep.typeText(steps.joined(separator: "\n") + "\n")

        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10), "recipe view did not open")
        return name
    }

    private struct Snapshot { var labels: [String: CGFloat]; var overlap: Bool; var top: String }

    private func snapshot() -> Snapshot {
        let screen = app.windows.firstMatch.frame
        var labels: [String: CGFloat] = [:]
        var stepFrames: [CGRect] = []
        let texts = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Step ' OR label BEGINSWITH 'Ing ' OR label == 'Instructions' OR label == 'More information'"))
        for el in texts.allElementsBoundByIndex {
            let f = el.frame
            guard f.intersects(screen), f.height > 0 else { continue }
            labels[el.label] = f.minY
            if el.label.hasPrefix("Step ") { stepFrames.append(f) }
        }
        var overlap = false
        if let more = labels["More information"] {
            let moreFrame = app.staticTexts["More information"].firstMatch.frame
            overlap = stepFrames.contains { $0.intersects(moreFrame) }
            _ = more
        }
        let top = labels.min { $0.value < $1.value }?.key ?? "-"
        return Snapshot(labels: labels, overlap: overlap, top: top)
    }

    /// Drags by a fixed distance and holds to stop momentum; checks that visible content moved consistently.
    private func controlledPass(up: Bool, steps: Int) -> Int {
        let win = app.windows.firstMatch
        let a = win.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: up ? 0.75 : 0.35))
        let b = win.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: up ? 0.35 : 0.75))
        var anomalies = 0
        var before = snapshot()
        for i in 0..<steps {
            a.press(forDuration: 0.05, thenDragTo: b, withVelocity: 800, thenHoldForDuration: 0.6)
            let after = snapshot()
            let shifts = before.labels.compactMap { k, y in after.labels[k].map { y - $0 } }.sorted()
            let median = shifts.isEmpty ? .nan : shifts[shifts.count / 2]
            let spread = shifts.isEmpty ? 0 : (shifts.last! - shifts.first!)
            log("\(up ? "down" : "up") #\(i) top=\(after.top) shift=\(median) spread=\(spread) common=\(shifts.count) overlap=\(after.overlap)")
            if after.overlap || spread > 5 { anomalies += 1 }
            if shifts.isEmpty && !after.labels.isEmpty && !before.labels.isEmpty { anomalies += 1; log("  JUMP: no common labels") }
            before = after
        }
        return anomalies
    }

    func test36_longRecipeScrolling() {
        let t0 = Date()
        openLongRecipe()
        log("opened after \(Date().timeIntervalSince(t0))s")
        shot("opened")
        // How long until the app answers a snapshot request again?
        let t1 = Date()
        _ = app.staticTexts[Self.recipeName].frame
        log("first snapshot took \(Date().timeIntervalSince(t1))s")
        XCTAssertEqual(app.keyboards.count, 0, "#28 keyboard visible on recipe view")
        var anomalies = controlledPass(up: true, steps: 22)
        anomalies += controlledPass(up: false, steps: 22)
        // Normal flicks, like a user scrolling quickly
        for i in 0..<8 {
            app.swipeUp(velocity: .fast)
            let s = snapshot(); log("flick down #\(i) top=\(s.top) overlap=\(s.overlap)")
            if s.overlap { anomalies += 1 }
        }
        for i in 0..<8 {
            app.swipeDown(velocity: .fast)
            let s = snapshot(); log("flick up #\(i) top=\(s.top) overlap=\(s.overlap)")
            if s.overlap { anomalies += 1 }
        }
        anomalies += controlledPass(up: true, steps: 22)
        log("ANOMALIES \(anomalies)")
        XCTAssertEqual(anomalies, 0)
    }

    func test35_groceryList() {
        XCTAssertEqual(app.keyboards.count, 0, "#28 keyboard visible on cookbooks")
        app.tabBars.buttons["Grocery List"].firstMatch.tap()
        let field = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Add an item'")).firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Milk\nEggs\nSalt to taste\n")
        // Add button path
        field.typeText("Butter")
        app.buttons["Add item"].firstMatch.tap()
        app.swipeDown() // dismiss keyboard
        var failures = 0
        for item in ["Milk", "Eggs", "Salt to taste", "Butter"] {
            let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", item)).firstMatch
            guard row.waitForExistence(timeout: 3) else { log("missing \(item)"); failures += 1; continue }
            log("row for \(item): label='\(row.label)' matches=\(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", item)).count)")
            for round in 0..<6 {
                let was = row.isSelected
                row.tap()
                let ok = NSPredicate(format: "isSelected == %@", NSNumber(value: !was))
                let exp = expectation(for: ok, evaluatedWith: row)
                if XCTWaiter.wait(for: [exp], timeout: 2) != .completed {
                    failures += 1
                    log("toggle failed \(item) round \(round) was=\(was) now=\(row.isSelected) label='\(row.label)'")
                    shot("toggle-fail-\(item)-\(round)")
                }
            }
        }
        log("toggle failures \(failures)")
        XCTAssertEqual(failures, 0)
        // Delete the "Other" section via its menu
        let menu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Options for'")).firstMatch
        XCTAssertTrue(menu.exists)
        menu.tap()
        app.buttons["Remove from List"].firstMatch.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.buttons.matching(NSPredicate(format: "label CONTAINS 'Milk'")).firstMatch)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 3), .completed, "section not deleted")
    }
}
