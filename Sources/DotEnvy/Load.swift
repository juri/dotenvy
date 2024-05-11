import Foundation

public struct DotEnvironment {
    public var environment: [String: String]
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

    public static var process: DotEnvironment {
        DotEnvironment(environment: ProcessInfo.processInfo.environment)
    }
}

extension DotEnvironment {
    public indirect enum Override {
        case some(DotEnvironment)
        case none
    }
}

extension DotEnvironment.Override {
    public static var process: DotEnvironment.Override {
        .some(.process)
    }
}

extension DotEnvironment {
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
            throw Failure.dataDecodingError(url.absoluteURL)
        }
        do {
            let keyValues = try parse(string: str)
            return keyValues
        } catch let error as ParseErrorWithLocation {
            throw Failure.parseError(error, str)
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    public static func make(
        url: URL = Self.defaultURL,
        overrides: DotEnvironment.Override = .process
    ) throws -> DotEnvironment {
        let values = try self.loadValues(url: url)
        return DotEnvironment(environment: values, overrides: overrides)
    }

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

extension DotEnvironment {
    public enum Failure: Error, Equatable {
        case dataDecodingError(URL)
        case parseError(ParseErrorWithLocation, String)
    }
}
