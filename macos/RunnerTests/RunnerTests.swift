import FlutterMacOS
import Cocoa
import XCTest

final class RunnerTests: XCTestCase {
  func testRunnerLoads() {
    XCTAssertNotNil(NSApplication.shared.delegate)
  }
}
