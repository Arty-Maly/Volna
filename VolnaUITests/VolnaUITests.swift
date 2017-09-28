import XCTest
import SwiftMonkey

class VolnaUITests: XCTestCase {
  var app: XCUIApplication!
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testStationTitleIsCorrectOnSelect() {
    let stationName = "Business FM"
    let cellsQuery = app.collectionViews.cells
    cellsQuery.otherElements.containing(.staticText, identifier: stationName).element.tap()
    let title = app.staticTexts.element(matching: .any, identifier: "Station Title").label
    
    XCTAssertEqual(title, stationName)
  }
  
  func testSelectedStationStaysHighlighted() {
    let welcomeTitle = XCUIApplication().staticTexts["Здраствуй, Друг!"]
    XCTAssert(welcomeTitle.exists)
  }
  
  func testHeartAppearsAfterStationSelectInAllView() {
    let app = XCUIApplication()
    let heartButton = app.buttons["Heart"]
    XCTAssertFalse(heartButton.exists)
    app.collectionViews.cells.otherElements.containing(.staticText, identifier:"Business FM").element.tap()
    XCTAssertTrue(heartButton.isEnabled)
    XCTAssertTrue(heartButton.exists)
  }
  
  func testHeartDoesNotExistBeforeStationSelection() {
    let app = XCUIApplication()
    let heartButton = app.buttons["Heart"]
    let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier:"Best FM").element.swipeLeft()
    XCTAssertFalse(heartButton.exists)
  }
  
  func testMonkey() {
    let application = XCUIApplication()
    
    // Workaround for bug in Xcode 7.3. Snapshots are not properly updated
    // when you initially call app.frame, resulting in a zero-sized rect.
    // Doing a random query seems to update everything properly.
    // TODO: Remove this when the Xcode bug is fixed!
    _ = application.descendants(matching: .any).element(boundBy: 0).frame
    
    // Initialise the monkey tester with the current device
    // frame. Giving an explicit seed will make it generate
    // the same sequence of events on each run, and leaving it
    // out will generate a new sequence on each run.
    let monkey = Monkey(frame: application.frame)
    //let monkey = Monkey(seed: 123, frame: application.frame)
    
    // Add actions for the monkey to perform. We just use a
    // default set of actions for this, which is usually enough.
    // Use either one of these, but maybe not both.
    // XCTest private actions seem to work better at the moment.
    // UIAutomation actions seem to work only on the simulator.
    monkey.addDefaultXCTestPrivateActions()
    //monkey.addDefaultUIAutomationActions()
    
    // Occasionally, use the regular XCTest functionality
    // to check if an alert is shown, and click a random
    // button on it.
    monkey.addXCTestTapAlertAction(interval: 100, application: application)
    
    // Run the monkey test indefinitely.
    monkey.monkeyAround()
  }
  
  
  private func verifyElementDoesNotExistsWhileWaiting(_ element: XCUIElement) {
    let elementExistsPredicate = NSPredicate(format: "exists == 0")
    expectation(for: elementExistsPredicate, evaluatedWith: element, handler: nil)
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertFalse(element.exists)
  }

}
