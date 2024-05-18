@testable import DotEnvy
import XCTest

final class ExportTests: XCTestCase {
    func testOverwrite() throws {
        setenv("KEY1", "ENVVALUE1", 1)
        let dotenv = try DotEnvironment.make(
            source: """
            KEY1=DOTENVVALUE1
            KEY2=DOTENVVALUE2
            """,
            overrides: .none
        )
        dotenv.export(overwrite: true)
        XCTAssertEqual(ProcessInfo.processInfo.environment["KEY1"], "DOTENVVALUE1")
        XCTAssertEqual(ProcessInfo.processInfo.environment["KEY2"], "DOTENVVALUE2")
    }

    func testNoOverwrite() throws {
        setenv("KEY1", "ENVVALUE1", 1)
        let dotenv = try DotEnvironment.make(
            source: """
            KEY1=DOTENVVALUE1
            KEY2=DOTENVVALUE2
            """,
            overrides: .none
        )
        dotenv.export(overwrite: false)
        XCTAssertEqual(ProcessInfo.processInfo.environment["KEY1"], "ENVVALUE1")
        XCTAssertEqual(ProcessInfo.processInfo.environment["KEY2"], "DOTENVVALUE2")
    }
}
