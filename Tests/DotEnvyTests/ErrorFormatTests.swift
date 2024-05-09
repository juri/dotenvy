@testable import DotEnvy
import XCTest

final class ErrorFormatTests: XCTestCase {
    func testMissingEqualsSignOneLine() throws {
        let source = """
        ASDF
        """
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                """
                   1: ASDF
                          ^

                Error on line 1: Missing equals sign
                """
            )
        }
    }

    func testMissingEqualsSignLine1of2() throws {
        let source = """
        ASDF
        ZAP=1
        """
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                """
                   1: ASDF
                          ^
                   2: ZAP=1

                Error on line 1: Missing equals sign
                """
            )
        }
    }

    func testMissingEqualsSignLine2of1() throws {
        let source = """
        ZAP=1
        ASDF
        """
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                """
                   1: ZAP=1
                   2: ASDF
                          ^

                Error on line 2: Missing equals sign
                """
            )
        }
    }

    func testMissingEqualsSignLine3of4() throws {
        let source = """
        POP=BANG
        ZAP=1
        ASDF
        SQUEAK=2
        """
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                """
                   2: ZAP=1
                   3: ASDF
                          ^
                   4: SQUEAK=2

                Error on line 3: Missing equals sign
                """
            )
        }
    }
}
