import Foundation

/// `DotEnvironment` encapsulates a dictionary and possible overrides.
///
/// The usual configuration for dotenv files is that you'd load the contents of the file
/// into ``environment`` and the process environment variables into ``overrides``.
/// You can also do more elaborate setups, such as multiple levels of `.env` files.
public struct DotEnvironment {
    /// The variables loaded into this environment.
    public var environment: [String: String]

    /// Override values.
    public var overrides: Override = .none

    public subscript(_ key: String) -> String? {
        switch self.overrides {
        case let .some(o):
            if let value = o[key] {
                return value
            }
        case .none:
            break
        }
        return self.environment[key]
    }

    /// A `DotEnvironment` that represents the process environment.
    public static var process: DotEnvironment {
        DotEnvironment(environment: ProcessInfo.processInfo.environment)
    }
}

extension DotEnvironment {
    /// Override values for a `DotEnvironment`.
    public indirect enum Override {
        case some(DotEnvironment)
        case none
    }
}

extension DotEnvironment.Override {
    /// A `DotEnvironment.Override` that represents the process environment.
    public static var process: DotEnvironment.Override {
        .some(.process)
    }
}

extension DotEnvironment {
    /// Load the contents of a dotenv file into a dictionary.
    ///
    /// Defaults to loading `.env` from the current working directory. If the file does not exist, an
    /// empty dictionary is returned.
    ///
    /// - Throws: ``LoadError`` if the file could not be decoded or parsed. If there's some other error
    ///           when opening the file, they are passed through.
    public static func loadValues(
        url: URL = Self.defaultURL
    ) throws -> [String: String] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            return [:]
        }
        guard let str = String(data: data, encoding: .utf8) else {
            throw LoadError.dataDecodingError(url.absoluteURL)
        }
        do {
            let keyValues = try parse(string: str)
            return keyValues
        } catch let error as ParseErrorWithLocation {
            throw LoadError.parseError(error, str)
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    /// Create a `DotEnvironment` from `url` and `overrides`.
    ///
    /// Defaults to loading `.env` from the current working directory and using the process environment
    /// variables as the overrides.
    public static func make(
        url: URL = Self.defaultURL,
        overrides: DotEnvironment.Override = .process
    ) throws -> DotEnvironment {
        let values = try self.loadValues(url: url)
        return DotEnvironment(environment: values, overrides: overrides)
    }

    /// Merge, or flatten, a `DotEnvironment` into a single dictionary.
    public func merge() -> [String: String] {
        switch self.overrides {
        case let .some(e):
            let overrideDict = e.merge()
            return self.environment.merging(overrideDict, uniquingKeysWith: { $1 })
        case .none:
            return self.environment
        }
    }

    public static var defaultURL: URL {
        URL(fileURLWithPath: ".env", isDirectory: false)
    }
}

/// DotEnvironment loading failures.
public enum LoadError: Error, Equatable {
    /// The data at URL could not be decoded as UTF-8.
    case dataDecodingError(URL)

    /// A parsing error occurred parsing the String.
    case parseError(ParseErrorWithLocation, String)
}

extension LoadError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .dataDecodingError(url):
            "Error decoding data at \(url)"
        case let .parseError(parseErrorWithLocation, source):
            parseErrorWithLocation.formatError(source: source)
        }
    }
}
