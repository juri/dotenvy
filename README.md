# DotEnvy

DotEnvy is a dotenv file parser for Swift. It allows you to load values from an `.env` file, similar to the libraries
for [node.js], [Python], [Ruby], etc.

DotEnvy supports multiline strings and variable substitution.

[node.js]: https://github.com/motdotla/dotenv
[Python]: https://pypi.org/project/python-dotenv/
[Ruby]: https://github.com/bkeepers/dotenv

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
