@testable import DotEnvy
import XCTest

final class LoadTests: XCTestCase {
    func testLoadDefaultFile() throws {
        try inTemporaryDirectory { tempDir in
            try Data("""
            KEY=value
            """.utf8).write(to: tempDir.appendingPathComponent(".env", isDirectory: false))
            FileManager.default.changeCurrentDirectoryPath(tempDir.path)
            let values = try DotEnvironment.loadValues()
            XCTAssertEqual(values, ["KEY": "value"])
        }
    }

    func testMakeDotEnvironmentWithDefaultFile() throws {
        try inTemporaryDirectory { tempDir in
            try Data("""
            TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1=filevalue1
            TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY2=filevalue2
            """.utf8).write(to: tempDir.appendingPathComponent(".env", isDirectory: false))
            FileManager.default.changeCurrentDirectoryPath(tempDir.path)
            setenv("TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1", "envvalue", 1)
            let dotEnv = try DotEnvironment.make()

            XCTAssertEqual(dotEnv["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1"], "envvalue")
            XCTAssertEqual(dotEnv["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY2"], "filevalue2")

            let values = dotEnv.merge()

            XCTAssertEqual(values["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1"], "envvalue")
            XCTAssertEqual(values["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY2"], "filevalue2")
        }
    }

    func testMakeDotEnvironmentWithDefaultFileNoOverrides() throws {
        try inTemporaryDirectory { tempDir in
            try Data("""
            TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1=filevalue1
            TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY2=filevalue2
            """.utf8).write(to: tempDir.appendingPathComponent(".env", isDirectory: false))
            FileManager.default.changeCurrentDirectoryPath(tempDir.path)
            setenv("TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1", "envvalue", 1)
            let dotEnv = try DotEnvironment.make(overrides: .none)

            XCTAssertEqual(dotEnv["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1"], "filevalue1")
            XCTAssertEqual(dotEnv["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY2"], "filevalue2")

            let values = dotEnv.merge()

            XCTAssertEqual(values["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY1"], "filevalue1")
            XCTAssertEqual(values["TEST_MAKE_DOT_ENVIRONMENT_WITH_DEFAULT_FILE_KEY2"], "filevalue2")
        }
    }

    func testMultipleOverrideLevels() throws {
        try inTemporaryDirectory { tempDir in
            try Data("""
            TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY1=file.private.value1
            TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY2=file.private.value2
            TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY3=file.private.value3
            """.utf8).write(to: tempDir.appendingPathComponent(".env.private", isDirectory: false))

            try Data("""
            TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY2=file.shared.value2
            TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY3=file.shared.value3
            TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY4=file.shared.value4
            """.utf8).write(to: tempDir.appendingPathComponent(".env.shared", isDirectory: false))

            FileManager.default.changeCurrentDirectoryPath(tempDir.path)
            setenv("TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY1", "envvalue1", 1)

            let dotEnv = try DotEnvironment.make(
                url: URL(fileURLWithPath: ".env.shared"),
                overrides: .some(try DotEnvironment.make(
                    url: URL(fileURLWithPath: ".env.private")
                ))
            )

            XCTAssertEqual(dotEnv["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY1"], "envvalue1")
            XCTAssertEqual(dotEnv["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY2"], "file.private.value2")
            XCTAssertEqual(dotEnv["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY3"], "file.private.value3")
            XCTAssertEqual(dotEnv["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY4"], "file.shared.value4")

            let values = dotEnv.merge()

            XCTAssertEqual(values["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY1"], "envvalue1")
            XCTAssertEqual(values["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY2"], "file.private.value2")
            XCTAssertEqual(values["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY3"], "file.private.value3")
            XCTAssertEqual(values["TEST_MAKE_MULTIPLE_OVERRIDE_LEVELS_KEY4"], "file.shared.value4")
        }
    }
}

private func inTemporaryDirectory(_ closure: (URL) throws -> Void) throws {
    let url = URL(
        filePath: UUID().uuidString,
        directoryHint: .isDirectory,
        relativeTo: URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
    ).absoluteURL
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    defer {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Error removing directory:", error)
        }
    }
    try closure(url)
}
