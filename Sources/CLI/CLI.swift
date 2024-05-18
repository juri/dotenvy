import ArgumentParser
import DotEnvy
import Foundation

@main
struct Tool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "dotenvy-tool",
        abstract: "Tool for working with dotenv files",
        subcommands: [Check.self, JSON.self]
    )
}

struct Check: ParsableCommand {
    static var configuration
        = CommandConfiguration(
            abstract: "Check syntax of input.",
            discussion: """
            In case of a syntax error, the error is printed to standard error
            and the command exits with failure code \(ExitCode.failure.rawValue).

            If there are no problems reading the input, nothing is printed
            and the command exits with \(ExitCode.success.rawValue).
            """
        )

    @Option(
        name: [.customShort("i"), .long],
        help: "Input. Standard input is used with -. If omitted, try to use .env in cwd"
    )
    var input: Input?

    func run() throws {
        _ = try loadInput(self.input)
    }
}

struct JSON: ParsableCommand {
    static var configuration
        = CommandConfiguration(
            abstract: "Convert input to JSON.",
            discussion: """
            The input is converted to a JSON object.

            In case of a syntax error, the error is printed to standard error and the
            command exits with failure code \(ExitCode.failure.rawValue).

            If there are no problems reading the input, the JSON value is printed to
            standard output and the command exits with \(ExitCode.success.rawValue).
            """
        )

    @Option(
        name: [.customShort("i"), .long],
        help: "Input. Standard input is used with -. If omitted, try to use .env in cwd"
    )
    var input: Input?

    @Flag(help: "Pretty print JSON")
    var pretty: Bool = false

    func run() throws {
        let values = try loadInput(self.input)
        let json = try JSONSerialization.data(
            withJSONObject: values,
            options: self.pretty ? [.prettyPrinted, .sortedKeys] : []
        )
        FileHandle.standardOutput.write(json)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}

enum Input: ExpressibleByArgument {
    case stdin
    case fileURL(FileURL)

    init?(argument: String) {
        if argument == "-" {
            self = .stdin
        } else if let fileURL = FileURL(argument: argument) {
            self = .fileURL(fileURL)
        } else {
            return nil
        }
    }
}

struct FileURL: ExpressibleByArgument {
    var url: URL

    init?(argument: String) {
        // the new URL(filePath:directoryHint:) is not available on Linux
        let url = URL(fileURLWithPath: argument, isDirectory: false)
        guard url.isFileURL else {
            return nil
        }
        self.url = url
    }
}

private func loadInput(_ input: Input?) throws -> [String: String] {
    if let input = input {
        let string = try readInput(input)
        do {
            return try DotEnvironment.parse(string: string)
        } catch let error as ParseErrorWithLocation {
            FileHandle.standardError.write(Data(error.formatError(source: string).utf8))
            FileHandle.standardError.write(Data("\n".utf8))
            throw ExitCode.failure
        }
    } else {
        do {
            return try DotEnvironment.loadValues()
        } catch let error as LoadError {
            FileHandle.standardError.write(Data(error.description.utf8))
            FileHandle.standardError.write(Data("\n".utf8))
            throw ExitCode.failure
        }
    }
}

private func readInput(_ input: Input) throws -> String {
    let data: Data
    switch input {
    case .stdin:
        data = FileHandle.standardInput.readDataToEndOfFile()
    case let .fileURL(fileURL):
        data = try Data(contentsOf: fileURL.url)
    }
    guard let string = String(data: data, encoding: .utf8) else {
        throw ValidationError("Input could not be decoded as UTF-8")
    }
    return string
}
