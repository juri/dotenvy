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

    func testInvalidKeyStartOnlyLine() throws {
        let source = """
        0POP=BANG
        """
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                """
                   1: 0POP=BANG
                      ^

                Error on line 1: Invalid start for a key: "0"
                """
            )
        }
    }

    func testInvalidEscapeSequence() throws {
        let source = #"""
        POP=BANG
        FOO1=Bar
        FLARP=hello \q world
        FOO2=Bar
        FOO3=Bar
        """#
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                #"""
                   2: FOO1=Bar
                   3: FLARP=hello \q world
                                    ^
                   4: FOO2=Bar

                Error on line 3: Invalid escape sequence
                """#
            )
        }
    }

    func testUnexpectedEOF() throws {
        let source = #"""
        POP=BANG
        FOO1=Bar
        FLARP=${
        """#
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                #"""
                   1: POP=BANG
                   2: FOO1=Bar
                   3: FLARP=${
                              ^

                Error on line 3: Unexpected end of data
                """#
            )
        }
    }

    func testUnknownKey() throws {
        let source = #"""
        FLARP=${UNKNOWN}
        """#
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                #"""
                   1: FLARP=${UNKNOWN}
                                      ^

                Error on line 1: Unknown key: "UNKNOWN"
                """#
            )
        }
    }

    func testUnterminatedVariable() throws {
        let source = #"""
        FLARP=${UNKNOWN
        """#
        do {
            _ = try parse(string: source)
            XCTFail()
        } catch let error as ParseErrorWithLocation {
            let formatted = formatError(source: source, error: error.error, errorLocation: error.location)
            XCTAssertEqual(
                formatted,
                #"""
                   1: FLARP=${UNKNOWN
                                     ^

                Error on line 1: Unterminated variable
                """#
            )
        }
    }
}
