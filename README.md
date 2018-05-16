# FilePathPattern for iOS
Regular expression based file path pattern matcher for iOS.

## Purpose
*FilePathPattern* is a utility for matching file paths against patterns, and for extracting matching parts into named variables. For example, the pattern `**/{name}.txt` can be used to match any file with a `.txt` extension and extract the filename into a variable named `name`; this pattern would match any of the following file paths:
```
    Desktop/notes.txt
    /var/log/error.txt
    /usr/share/vim/vim80/syntax/README.txt
```

## Installation
To install using CocoaPods, add the following to your Podfile:
```pod 'FilePathPattern', '~> 0.1.2'```

## Sample usage
Import the header file:
```
    #import "IFFilePathPattern.h"
```
Test if a path string matches a pattern and extract matching variables:
```
    NSDictionary *matches = [IFFilePathPattern matchPath:@"images/fruit/orange.jpg"
                                            usingPattern:@"images/{type}/{name}.(jpg|png)"];
    if (matches) {
        NSString *type = matches[@"type"]; // => 'fruit'
        NSString *name = matches[@"name"]; // => 'orange'
    }
```
## Pattern syntax
The pattern syntax is an amalgamation of the standard regular expression syntax and the familiar file glob syntax. The specific differences from standard regex syntax are:
 * The full stop (period) `.` is interpreted as a literal `.` character and not as a character wildcard.
 * A single asterisk `*`  is interpreted as any non-forward slash (`/`) character, and not as a zero-or-more quantifier. This makes it easy to match single path components (e.g. `*/*`).
 * A double asterisk `**` is interpreted as any character, and is useful for matching deeply nested paths (e.g. `**/file`).
 * Parenthesis can be used to define expression groups (e.g. `(a|b)`) but are non-capturing.
 * The `?` and `+` quantifiers, and alternation (the pipe symbol `|`) work as in normal regular expressions (note that this means `?` is different than in normal file globs).
 * Character classes, using `[]` or standard abbreviations like `\w` or `\s` all work as in normal regular expressions. 
 * Variable patterns can be used to capture data from matching paths. A variable pattern is a variable name within curly braces, e.g. `{name}`. A variable pattern by default matches the same as the `*` pattern, but this behaviour can be modified by adding a colon followed by an alternative pattern to the end of the variable name, e.g. `{name:aaa|bbb}`.
 * Quantifiers like `a{2,5}` will work, but not within a variable pattern.
 
## Sample patterns
 * Extract file name from all matching HTML files: `**/{name}.html`.
 * Extract a title with an optional date prefix from matching docx files: `docs/({id}-)?{title}.docx`. This will match files like `docs/123-Guides.docx` or `docs/Price List.docx`.
 * Match text files stored by date and extract the date fields: `logs/{year:\d+}-{month:\d+}-{day:\d+}.txt`. This will match files like `logs/2016-03-17.txt`.
  
## Limitations
 * Variable patterns will produce unexpected results (or not work at all) when used with quantifiers (e.g. `{name}*`, `({name}){1,2}`).
 * There's no guarantee that a pattern will compile to a valid regular expression; basic patterns should be fine, but complex patterns may produce exceptions. In particular, including variable quantifiers within a variable pattern (e.g. `{var:(abc){2,3}}`) will likely not work.
 
## Licence
*FilePathPattern* is released under the Apache 2.0 OSS licence.

