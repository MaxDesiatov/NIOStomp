import XCTest
@testable import NIOStomp

final class NIOStompTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NIOStomp().text, "Hello, World!")
    }
}
