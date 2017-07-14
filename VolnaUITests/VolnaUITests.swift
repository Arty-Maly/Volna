import XCTest

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
  
  private func verifyElementDoesNotExistsWhileWaiting(_ element: XCUIElement) {
    let elementExistsPredicate = NSPredicate(format: "exists == 0")
    expectation(for: elementExistsPredicate, evaluatedWith: element, handler: nil)
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertFalse(element.exists)
  }

}
