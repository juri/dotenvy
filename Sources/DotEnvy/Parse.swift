import Foundation

extension DotEnvironment {
    /// Parse dotenv formatted string.
    ///
    /// - Throws: `ParseErrorWithLocation`
    public static func parse(string: String) throws -> [String: String] {
        var sub = string[...]
        do {
            let values = try Self.parse(substring: &sub)
            return values
        } catch let error as ParseError {
            throw ParseErrorWithLocation(error: error, location: sub.startIndex)
        }
    }

    /// Parse dotenv formatted substring.
    ///
    /// `substring.startIndex` is moved while the parsing happens. If the method throws,
    /// `startIndex` is where the error occurred.
    ///
    /// - Throws: `ParseError`
    public static func parse(substring: inout Substring) throws -> [String: String] {
        var values = [String: String]()

        while !substring.isEmpty {
            skipSpace(in: &substring)
            guard let first = substring.first else { break }
            switch first {
            case "\n":
                substring.removeFirst()
                continue
            case "#":
                skipLine(in: &substring)
            default:
                let (key, value) = try parseKeyValue(in: &substring, values: values)
                values[key] = value
            }
        }

        return values
    }
}

/// Errors that occur during parsing.
///
/// `ParseError` does not include information about the error location. That information
/// can be derived from the location where the parsed substring was left at by ``parse(substring:)``.
///
/// - SeeAlso: If you call ``parse(string:)``, the thrown error is ``ParseErrorWithLocation`` which does
///            include the location information.
public enum ParseError: Error, Equatable {
    case invalidEscapeSequence
    case invalidKeyStart(Character)
    case missingEquals
    case unexpectedEnd
    case unknownVariable(String)
    case unterminatedQuote
    case unterminatedVariable
}

extension ParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidEscapeSequence: "Invalid escape sequence"
        case let .invalidKeyStart(start): #"Invalid start for a key: "\#(start)""#
        case .missingEquals: "Missing equals sign"
        case .unexpectedEnd: "Unexpected end of data"
        case let .unknownVariable(key): #"Unknown variable: "\#(key)""#
        case .unterminatedQuote: "Unterminated quote"
        case .unterminatedVariable: "Unterminated variable"
        }
    }
}

/// Encapsulates a ``ParseError`` along with location in the original input.
public struct ParseErrorWithLocation: Error, Equatable {
    public var error: ParseError
    public var location: String.Index
}

func parseKeyValue(in substring: inout Substring, values: [String: String]) throws -> (String, String) {
    let key = try parseKey(in: &substring)
    skipSpace(in: &substring)
    try skipEquals(in: &substring)
    skipSpace(in: &substring)
    guard let first = substring.first else { return (key, "") }
    switch first {
    case "\n":
        return (key, "")
    case #"""#, "'":
        substring.removeFirst()
        let value = try parseQuoted(quote: first, in: &substring, values: values)
        return (key, value)
    default:
        let value = try parseUnquotedValue(in: &substring, values: values)
        return (key, value)
    }
}

func parseKey(in substring: inout Substring) throws -> String {
    guard let first = substring.first else { throw ParseError.unexpectedEnd }
    guard isKeyStart(first) else { throw ParseError.invalidKeyStart(first) }
    let tail = substring.dropFirst().prefix(while: isKeyTail)
    substring.removeFirst(tail.count + 1)
    return String(first) + tail
}

func skipLine(in substring: inout Substring) {
    while let first = substring.first, first != "\n" {
        substring.removeFirst()
    }
}

func skipSpace(in substring: inout Substring) {
    while let first = substring.first, isTabOrSpace(first) {
        substring.removeFirst()
    }
}

func skipEquals(in substring: inout Substring) throws {
    guard substring.first == "=" else { throw ParseError.missingEquals }
    substring.removeFirst()
}

func parseQuoted(quote: Character, in substring: inout Substring, values: [String: String]) throws -> String {
    var output = [Character]()
    var escaped = false
    var last: Character?
    let escapeSequences = quote == #"""#
    while !substring.isEmpty, case let first = substring.removeFirst() {
        if escaped {
            switch first {
            case #"\"#: output.append(first)
            case "n": output.append(contentsOf: escapeSequences ? "\n" : #"\n"#)
            case quote: output.append(first)
            case "'": output.append(first)
            case "t": output.append(contentsOf: escapeSequences ? "\t" : #"\t"#)
            case "r": output.append(contentsOf: escapeSequences ? "\r" : #"\r"#)
            case "$": output.append(first)
            default: throw ParseError.invalidEscapeSequence
            }
            escaped = false
            continue
        }
        if first == #"\"# {
            escaped = true
            continue
        }
        if first == "$" && substring.first == "{" {
            substring.removeFirst()
            let key = try parseKey(in: &substring)
            guard substring.first == "}" else { throw ParseError.unterminatedVariable }
            substring.removeFirst()
            guard let variableValue = values[key] else { throw ParseError.unknownVariable(key) }
            output.append(contentsOf: variableValue)
            continue
        }
        last = first
        if first == quote {
            break
        }
        output.append(first)
    }
    guard last == quote else {
        throw ParseError.unterminatedQuote
    }
    return String(output)
}

func parseUnquotedValue(in substring: inout Substring, values: [String: String]) throws -> String {
    var output = [Character]()
    var escaped = false
    var space = [Character]()

    func collect(_ c: Character) {
        output.append(contentsOf: space)
        space.removeAll(keepingCapacity: true)
        output.append(c)
    }

    func collect(_ s: String) {
        output.append(contentsOf: space)
        space.removeAll(keepingCapacity: true)
        output.append(contentsOf: s)
    }

    while !substring.isEmpty, case let first = substring.removeFirst() {
        if escaped {
            switch first {
            case #"\"#: collect(first)
            case "n": collect("\\n")
            case "'": collect(first)
            case "t": collect("\\t")
            case "r": collect("\\r")
            case "$": collect(first)
            case "#": collect(first)
            default: throw ParseError.invalidEscapeSequence
            }
            escaped = false
            continue
        }
        if first == #"\"# {
            escaped = true
            continue
        }
        if first == "#" {
            skipLine(in: &substring)
            break
        }
        if first == "$" && substring.first == "{" {
            substring.removeFirst()
            let key = try parseKey(in: &substring)
            guard substring.first == "}" else { throw ParseError.unterminatedVariable }
            substring.removeFirst()
            guard let variableValue = values[key] else { throw ParseError.unknownVariable(key) }
            collect(variableValue)
            continue
        }
        if first == "\n" {
            break
        }
        if isTabOrSpace(first) {
            space.append(first)
        } else {
            collect(first)
        }
    }

    return String(output)
}

func isTabOrSpace(_ c: Character) -> Bool { c == " " || c == "\t" }
func isKeyStart(_ c: Character) -> Bool { (c.isASCII && c.isLetter) || c == "_" }
func isKeyTail(_ c: Character) -> Bool { c.isASCII && (c.isLetter || c.isNumber || c == "_") }
