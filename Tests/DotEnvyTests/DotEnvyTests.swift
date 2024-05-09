@testable import DotEnvy
import XCTest

final class DotEnvyTests: XCTestCase {
    func testEmptyString() throws {
        let values = try parse(string: "")
        XCTAssertEqual(values, [:])
    }

    func testSpacesOnly() throws {
        let values = try parse(string: "  \t")
        XCTAssertEqual(values, [:])
    }

    func testSpacesAndNewlinesOnly() throws {
        let values = try parse(string: "\n  \n\n\t \n \t\n")
        XCTAssertEqual(values, [:])
    }

    func testCommentsOnly() throws {
        let values = try parse(string: "\n  \n# Hello\n\t # Wörld\n \t\n")
        XCTAssertEqual(values, [:])
    }

    func testKeyOnly() throws {
        let values = try parse(string: "FOO=")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testLeadingSpace() throws {
        let values = try parse(string: "   FOO=")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testSpaceAfterKey() throws {
        let values = try parse(string: "   FOO =")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testSpaceAfterEquals() throws {
        let values = try parse(string: "   FOO =  ")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testTrailingComment() throws {
        let values = try parse(string: "   FOO =  # Nothing here")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testKeyCharacters() throws {
        let values = try parse(string: "Fpo123_O9abO=")
        XCTAssertEqual(values, ["Fpo123_O9abO": ""])
    }

    func testUnquotedValue() throws {
        let values = try parse(string: "FOO=BAR")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testSpaceBeforeUnquotedValue() throws {
        let values = try parse(string: "FOO=   BAR")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testSpaceAfterUnquotedValue() throws {
        let values = try parse(string: "FOO=BAR   ")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testDoubleQuotedValue() throws {
        let values = try parse(string: #"FOO="BAR""#)
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testSingleQuotedValue() throws {
        let values = try parse(string: "FOO='BAR'")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testEscapedNewlineInQuotes() throws {
        let values = try parse(string: #"FOO="B\nAR""#)
        XCTAssertEqual(values, ["FOO": "B\nAR"])
    }

    func testEscapedTabInQuotes() throws {
        let values = try parse(string: #"FOO="B\tAR""#)
        XCTAssertEqual(values, ["FOO": "B\tAR"])
    }

    func testEscapedQuoteInQuotes() throws {
        let values = try parse(string: #"FOO="B\"AR""#)
        XCTAssertEqual(values, ["FOO": "B\"AR"])
    }

    func testQuotesInUnquoted() throws {
        let values = try parse(string: #"FOO={"key": "value"}"#)
        XCTAssertEqual(values, ["FOO": "{\"key\": \"value\"}"])
    }

    func testMultiplePairs() throws {
        let values = try parse(string: #"""
        K1=v1
        K2=v2
        K3="v3"
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3", "K4": "v4"])
    }

    func testMultiline() throws {
        let values = try parse(string: #"""
        K1=v1
        K2=v2
        K3="v3
        v3 line 2"
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3\nv3 line 2", "K4": "v4"])
    }

    func testMultilineSingleQuoted() throws {
        let values = try parse(string: #"""
        K1=v1
        K2=v2
        K3='v3
        v3 "line 2'
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3\nv3 \"line 2", "K4": "v4"])
    }

    func testCommentsAfterLines() throws {
        let values = try parse(string: #"""
        K1=v1
        K2=v2 # comment
        K3="v3 # not comment
        v3 line 2" # comment
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3 # not comment\nv3 line 2", "K4": "v4"])
    }
}
