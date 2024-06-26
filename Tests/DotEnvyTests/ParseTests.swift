@testable import DotEnvy
import XCTest

final class DotEnvyTests: XCTestCase {
    func testEmptyString() throws {
        let values = try DotEnvironment.parse(string: "")
        XCTAssertEqual(values, [:])
    }

    func testSpacesOnly() throws {
        let values = try DotEnvironment.parse(string: "  \t")
        XCTAssertEqual(values, [:])
    }

    func testSpacesAndNewlinesOnly() throws {
        let values = try DotEnvironment.parse(string: "\n  \n\n\t \n \t\n")
        XCTAssertEqual(values, [:])
    }

    func testCommentsOnly() throws {
        let values = try DotEnvironment.parse(string: "\n  \n# Hello\n\t # Wörld\n \t\n")
        XCTAssertEqual(values, [:])
    }

    func testKeyOnly() throws {
        let values = try DotEnvironment.parse(string: "FOO=")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testKeyOnlyWithNewline() throws {
        let values = try DotEnvironment.parse(string: """
        FOO=

        """)
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testLeadingSpace() throws {
        let values = try DotEnvironment.parse(string: "   FOO=")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testSpaceAfterKey() throws {
        let values = try DotEnvironment.parse(string: "   FOO =")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testSpaceAfterEquals() throws {
        let values = try DotEnvironment.parse(string: "   FOO =  ")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testTrailingComment() throws {
        let values = try DotEnvironment.parse(string: "   FOO =  # Nothing here")
        XCTAssertEqual(values, ["FOO": ""])
    }

    func testKeyCharacters() throws {
        let values = try DotEnvironment.parse(string: "Fpo123_O9abO=")
        XCTAssertEqual(values, ["Fpo123_O9abO": ""])
    }

    func testUnquotedValue() throws {
        let values = try DotEnvironment.parse(string: "FOO=BAR")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testSpaceBeforeUnquotedValue() throws {
        let values = try DotEnvironment.parse(string: "FOO=   BAR")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testSpaceAfterUnquotedValue() throws {
        let values = try DotEnvironment.parse(string: "FOO=BAR   ")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testDoubleQuotedValue() throws {
        let values = try DotEnvironment.parse(string: #"FOO="BAR""#)
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testSingleQuotedValue() throws {
        let values = try DotEnvironment.parse(string: "FOO='BAR'")
        XCTAssertEqual(values, ["FOO": "BAR"])
    }

    func testEscapedNewlineInQuotes() throws {
        let values = try DotEnvironment.parse(string: #"FOO="B\nAR""#)
        XCTAssertEqual(values, ["FOO": "B\nAR"])
    }

    func testEscapedTabInQuotes() throws {
        let values = try DotEnvironment.parse(string: #"FOO="B\tAR""#)
        XCTAssertEqual(values, ["FOO": "B\tAR"])
    }

    func testEscapedQuoteInQuotes() throws {
        let values = try DotEnvironment.parse(string: #"FOO="B\"AR""#)
        XCTAssertEqual(values, ["FOO": "B\"AR"])
    }

    func testQuotesInUnquoted() throws {
        let values = try DotEnvironment.parse(string: #"FOO={"key": "value"}"#)
        XCTAssertEqual(values, ["FOO": "{\"key\": \"value\"}"])
    }

    func testEscapeSequences() throws {
        let values = try DotEnvironment.parse(string: ##"""
        DOUBLE="d1\n\"\'\\\t\r2"
        SINGLE='s1\n\t\r2'
        UNQUOTED=u1\n\\\'\t\r\#2
        """##)
        XCTAssertEqual(values["DOUBLE"], "d1\n\"\'\\\t\r2")
        XCTAssertEqual(values["SINGLE"], #"s1\n\t\r2"#)
        XCTAssertEqual(values["UNQUOTED"], #"u1\n\'\t\r#2"#)
    }

    func testEscapedDoubleQuote() throws {
        let values = try DotEnvironment.parse(string: #"FOO=\"bar"#)
        XCTAssertEqual(values["FOO"], #""bar"#)
    }

    func testMultiplePairs() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=v2
        K3="v3"
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3", "K4": "v4"])
    }

    func testMultiplePairsEmoji() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=v2
        K3="👩🏽‍🤝‍👨🏿"
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "👩🏽‍🤝‍👨🏿", "K4": "v4"])
    }

    func testMultiline() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=v2
        K3="v3
        v3 line 2"
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3\nv3 line 2", "K4": "v4"])
    }

    func testMultilineSingleQuoted() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=v2
        K3='v3
        v3 "line 2'
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3\nv3 \"line 2", "K4": "v4"])
    }

    func testCommentsAfterLines() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=v2 # comment
        K3="v3 # not comment
        v3 line 2" # comment
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v2", "K3": "v3 # not comment\nv3 line 2", "K4": "v4"])
    }

    func testVariableReplacementUnquoted() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=${K1}v2
        K3=\${K1}v3
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v1v2", "K3": "${K1}v3", "K4": "v4"])
    }

    func testVariableReplacementQuoted() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2="${K1}v2"
        K3="\${K1}v3"
        K4='v4'
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v1v2", "K3": "${K1}v3", "K4": "v4"])
    }

    func testVariableReplacementRecursive() throws {
        let values = try DotEnvironment.parse(string: #"""
        K1=v1
        K2=${K1}v2
        K3=${K2}v3
        K4='v4'
        K5=${K3}
        """#)
        XCTAssertEqual(values, ["K1": "v1", "K2": "v1v2", "K3": "v1v2v3", "K4": "v4", "K5": "v1v2v3"])
    }

    func testThrowsInvalidEscapeSequence() throws {
        let source = #"""
        FOO="bad \q escape"
        """#
        XCTAssertThrowsError(try DotEnvironment.parse(string: source)) { error in
            guard let error = error as? ParseErrorWithLocation else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.error, ParseError.invalidEscapeSequence)
        }
    }

    func testThrowsUnterminatedVariable() throws {
        let source = #"""
        FOO="unterminated ${VARIABLE"
        """#
        XCTAssertThrowsError(try DotEnvironment.parse(string: source)) { error in
            guard let error = error as? ParseErrorWithLocation else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.error, ParseError.unterminatedVariable)
        }
    }

    func testThrowsUnknownVariable() throws {
        let source = #"""
        FOO="unknown ${VARIABLE}"
        """#
        XCTAssertThrowsError(try DotEnvironment.parse(string: source)) { error in
            guard let error = error as? ParseErrorWithLocation else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.error, ParseError.unknownVariable("VARIABLE"))
        }
    }
}
