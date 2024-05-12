import ArgumentParser
import DotEnvy
import Foundation

@main
struct Tool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "dotenvy-tool",
        abstract: "Tool for working with dotenv files",
        subcommands: [Check.self]
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

    @Argument(help: "Input file. Standard input is used if omitted")
    var file: FileURL?

    func validate() throws {
        _ = try self.file?.url.checkResourceIsReachable()
    }

    func run() throws {
        let string = try readInput(self.file)
        do {
            _ = try DotEnvironment.parse(string: string)
        } catch let error as ParseErrorWithLocation {
            FileHandle.standardError.write(Data(error.formatError(source: string).utf8))
            FileHandle.standardError.write(Data("\n".utf8))
            throw ExitCode.failure
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

private func readInput(_ file: FileURL?) throws -> String {
    let data: Data
    if let file {
        data = try Data(contentsOf: file.url)
    } else {
        data = FileHandle.standardInput.readDataToEndOfFile()
    }
    guard let string = String(data: data, encoding: .utf8) else {
        throw ValidationError("Input could not be decoded as UTF-8")
    }
    return string
}
