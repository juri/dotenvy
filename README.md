# DotEnvy

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjuri%2Fdotenvy%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/juri/dotenvy)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjuri%2Fdotenvy%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/juri/dotenvy)

DotEnvy is a dotenv file parser for Swift. It allows you to load values from an `.env` file, similar to the libraries
for [node.js], [Python], [Ruby], [Rust] (I accidentally used the same name they use; apologies!) etc.

DotEnvy supports multiline strings and variable substitution.

[node.js]: https://github.com/motdotla/dotenv
[Python]: https://pypi.org/project/python-dotenv/
[Ruby]: https://github.com/bkeepers/dotenv
[Rust]: https://docs.rs/dotenvy/latest/dotenvy/

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
    _ = try parse(string: source)
} catch let error as ParseErrorWithLocation {
    let formatted = formatError(source: source, error: error)
    print(formatted)
}
```

outputs

```
   1: KEY="VALUE
                ^

Error on line 1: Unterminated quote
```
