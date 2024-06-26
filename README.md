# DotEnvy

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjuri%2Fdotenvy%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/juri/dotenvy)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjuri%2Fdotenvy%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/juri/dotenvy)
![Swift build status](https://github.com/juri/dotenvy/actions/workflows/build.yml/badge.svg)

DotEnvy is a dotenv file parser for Swift. It allows you to load values from an `.env` file, similar to the libraries
for [node.js], [Python], [Ruby], [Rust][Rust][^1] etc.

[^1]: I accidentally used the same name they use; apologies!

DotEnvy supports multiline strings and variable substitution.

[node.js]: https://github.com/motdotla/dotenv
[Python]: https://pypi.org/project/python-dotenv/
[Ruby]: https://github.com/bkeepers/dotenv
[Rust]: https://docs.rs/dotenvy/latest/dotenvy/

## Documentation

For more detailed syntax examples and API documentation visit DotEnvy's [documentation] on Swift Package Index.

[documentation]: https://swiftpackageindex.com/juri/dotenvy/documentation/dotenvy

## Supported format

The dotenv format does not have a specification, but this library supports the common features. The syntax
resembles Bash. Examples:

```sh
KEY=value
KEY2 = "quoted value"
 
 KEY3= unquoted value "with" quotes inside
# comment
KEY4 ='quoted value referring to ${KEY3}' # trailing comment
KEY5=unquoted value referring to ${KEY4}
KEY6="multiline
string"
```

## Error reporting

DotEnvy has helpful error reporting on syntax errors.

```swift
let source = #"""
KEY="VALUE
"""#
do {
    _ = try DotEnvironment.parse(string: source)
} catch let error as ParseErrorWithLocation {
    let formatted = error.formatError(source: source)
    print(formatted)
}
```

outputs

```
   1: KEY="VALUE
                ^

Error on line 1: Unterminated quote
```

## Command Line

There's also a command line tool, `dotenv-tool`. It supports checking dotenv files for syntax errors and converting
them to JSON. To install, run:

```sh
swift build -c release
cp .build/release/dotenv-tool /usr/local/bin
```
