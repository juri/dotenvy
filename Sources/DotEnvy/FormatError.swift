extension ParseErrorWithLocation {
    /// Format the error that occurred when parsing `source`.
    public func formatError(source: String) -> String {
        self.error.formatError(source: source, errorLocation: self.location)
    }
}

extension ParseError {
    /// Format the error that occurred on `errorLocation` when parsing `source`.
    public func formatError(source: String, errorLocation: String.Index) -> String {
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
            case onLineWithError(OnLineWithError)
            case errorIndicatorAdded(ErrorIndicatorAdded)
            case lineAfterErrorIndicatorAdded(LineAfterErrorIndicatorAdded)

            struct ErrorNotFound {
                var lineStart: String.Index
            }

            struct OnLineWithError {
                var lineStart: String.Index
                var column: Int
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
                } else if index == errorLocation {
                    let column = source.distance(from: substate.lineStart, to: index)
                    state = .onLineWithError(.init(lineStart: substate.lineStart, column: column))
                }

            case let .onLineWithError(substate):
                if char == "\n" {
                    lines.append(formattedLineNumber + source[substate.lineStart ... index])
                    lines.append(makeErrorLine(errorAt: substate.column)[...])
                    let lineStart = source.index(after: index)
                    state = .errorIndicatorAdded(.init(lineStart: lineStart, line: lineCounter))
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

        case let .onLineWithError(substate):
            let lastLine = source.suffix(from: substate.lineStart)
            lines.append(formattedLineNumber + lastLine + "\n")
            let distance = lastLine.distance(from: lastLine.startIndex, to: errorLocation)
            lines.append(makeErrorLine(errorAt: distance)[...])
            errorLine = lineCounter

        case let .errorIndicatorAdded(substate):
            lines.append(formattedLineNumber + source[substate.lineStart ..< source.endIndex] + "\n")
            errorLine = substate.line

        case let .lineAfterErrorIndicatorAdded(substate):
            errorLine = substate.line
        }

        return """
        \(lines.suffix(4).joined())
        Error on line \(errorLine): \(self)
        """
    }
}
