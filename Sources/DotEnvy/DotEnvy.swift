import Foundation

public func parse(string: String) throws -> [String: String] {
    var sub = string[...]
    do {
        let values = try parse(substring: &sub)
        return values
    } catch let error as ParseError {
        throw ParseErrorWithLocation(error: error, location: sub.startIndex)
    }
}

public func parse(substring: inout Substring) throws -> [String: String] {
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

public func formatError(source: String, error: ParseError, errorLocation: String.Index) -> String {
    var lines = [Substring]()
    var lineCounter = 1
    let paddedLineNumberLength = 4
    let fullLineNumberLength = paddedLineNumberLength + 2

    var formattedLineNumber: String {
        let str = String(lineCounter)
        let length = str.count
        if length < paddedLineNumberLength {
            return String(repeating: " ", count: 4 - length) + str + ": "
        }
        return str + ": "
    }

    func makeErrorLine(errorAt column: Int) -> String {
        String(repeating: " ", count: column + fullLineNumberLength) + "^\n"
    }

    enum State {
        case errorNotFound(ErrorNotFound)
        case errorIndicatorAdded(ErrorIndicatorAdded)
        case lineAfterErrorIndicatorAdded(LineAfterErrorIndicatorAdded)

        struct ErrorNotFound {
            var lineStart: String.Index
        }

        struct ErrorIndicatorAdded {
            var lineStart: String.Index
            var line: Int
        }

        struct LineAfterErrorIndicatorAdded {
            var line: Int
        }
    }

    var state = State.errorNotFound(.init(lineStart: source.startIndex))

    for (char, index) in zip(source, source.indices) {
        switch state {
        case let .errorNotFound(substate):
            if char == "\n" {
                lines.append(formattedLineNumber + source[substate.lineStart ... index])

                let lineStart = source.index(after: index)

                if index == errorLocation {
                    let col = source.distance(from: substate.lineStart, to: index)

                    lines.append(makeErrorLine(errorAt: col)[...])
                    state = .errorIndicatorAdded(.init(lineStart: lineStart, line: lineCounter))
                } else {
                    state = .errorNotFound(.init(lineStart: lineStart))
                }

                lineCounter += 1
            }

        case let .errorIndicatorAdded(substate):
            if char == "\n" {
                lines.append(formattedLineNumber + source[substate.lineStart ... index])

                state = .lineAfterErrorIndicatorAdded(.init(line: substate.line))
            }

        case .lineAfterErrorIndicatorAdded:
            break
        }
    }

    var errorLine = 1

    switch state {
    case let .errorNotFound(substate):
        let lastLine = source.suffix(from: substate.lineStart)
        lines.append(formattedLineNumber + lastLine + "\n")
        if errorLocation == source.endIndex {
            lines.append(makeErrorLine(errorAt: lastLine.count)[...])
            errorLine = lineCounter
        } else if errorLocation >= substate.lineStart && errorLocation < source.endIndex {
            let distance = lastLine.distance(from: lastLine.startIndex, to: errorLocation)
            lines.append(makeErrorLine(errorAt: distance)[...])
            errorLine = lineCounter
        }

    case let .errorIndicatorAdded(substate):
        lines.append(formattedLineNumber + source[substate.lineStart ..< source.endIndex] + "\n")
        errorLine = substate.line

    case let .lineAfterErrorIndicatorAdded(substate):
        errorLine = substate.line
    }

    return """
    \(lines.suffix(4).joined())
    Error on line \(errorLine): \(error)
    """
}

public enum ParseError: Error {
    case invalidEscapeSequence
    case invalidKeyStart(Character)
    case missingEquals
    case unexpectedEOF
    case unknownKey(String)
    case unterminatedVariable
}

extension ParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidEscapeSequence: "Invalid escape sequence"
        case let .invalidKeyStart(start): #"Invalid start for a key: "\#(start)""#
        case .missingEquals: "Missing equals sign"
        case .unexpectedEOF: "Unexpected end of file"
        case let .unknownKey(key): #"Unknown key: "\#(key)""#
        case .unterminatedVariable: "Unterminated variable"
        }
    }
}

public struct ParseErrorWithLocation: Error {
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
    guard let first = substring.first else { throw ParseError.unexpectedEOF }
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
    while !substring.isEmpty, case let first = substring.removeFirst() {
        if escaped {
            switch first {
            case #"\"#: output.append(first)
            case "n": output.append("\n")
            case quote: output.append(first)
            case "'": output.append(first)
            case "t": output.append("\t")
            case "r": output.append("\r")
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
            guard let variableValue = values[key] else { throw ParseError.unknownKey(key) }
            output.append(contentsOf: variableValue)
            continue
        }
        if first == quote {
            break
        }
        output.append(first)
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
            case "n": collect("\n")
            case "'": collect(first)
            case "t": collect("\t")
            case "r": collect("\r")
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
            guard let variableValue = values[key] else { throw ParseError.unknownKey(key) }
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
