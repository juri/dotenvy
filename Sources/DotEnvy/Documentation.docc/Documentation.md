# ``DotEnvy``

DotEnvy is a Swift library for loading dotenv files and combining their values with the system environment.

## Overview

Dotenv files are variable definition files in a Bash-style syntax, commonly used during software development
to keep values the software would in production load from the environment variables. The syntax is not formally
specified, but there are mostly-compatible implementations for several programming languages used in server
software development.

The most common workflow is to use your version control system's ignore mechanism for a file called `.env`
in the project root. Then each developer will insert whatever values they want for the commonly used environment
variables into that file. Then they'll use the values in `.env` as fallbacks for the missing environment variables;
i.e, if a variable is defined in the environment, the software will use it, but if not, it'll use the value
from `.env`.

DotEnvy has facilities making that workflow easy, but it exposes enough of its mechanisms that you can built whatever
system is suitable for your project on top of it.

## Syntax Example

The dotenv syntax, in its most basic form, looks like this:

```sh
KEY=value
```

Keys must start with an ASCII letter or underscore, and must consist of of ASCII letters, numbers and underscores. It's
customary to use all-caps, but DotEnvy does not enforce that.

Values can be unquoted, single quoted (surrounded by `'` symbols) or double quoted (surrounded by `"` symbols). All
the keys in this example have the same value:

```sh
KEY1=value
KEY2='value'
KEY3="value"
```

An unquoted value ends at newline; quoted values may be multiline. Some escape sequences are supported in
double quoted strings (`\n`, `\r`, `\t`); in single quoted and unquoted strings escape sequences go unprocessed.

```sh
MULTILINE="foo
bar"
DOUBLE="foo\nbar"
SINGLE='foo\nbar'
UNQUOTED=foo\nbar
```

Here `MULTILINE` and `DOUBLE` have a newline in them. `SINGLE` and `UNQUOTED` have the character sequence
`\n`.

There's support for variable substitution using the following syntax:

```sh
KEY1=hello
KEY2=${KEY1}, world
```

Spaces are allowed around both keys and values. In unquoted values leading and trailing spaces are trimmed.

## API Example

The following code will load `.env` from the current working directory, use the process environment variables
as overrides for the values the file, and output a helpfully formatted error if there was a syntax error:
file.

```swift
import DotEnvy

func env() -> [String: String] {
    do {
        let environment = try DotEnvironment.make()
        return environment.merge()
    } catch {
        print("Error loadind dotenv:\n\(error)")
    }
}
```

## Topics

### Group
