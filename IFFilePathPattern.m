// Copyright 2018 InnerFunction Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Julian Goacher on 16/05/2018.
//  Copyright © 2018 InnerFunction Ltd. All rights reserved.
//

#import "IFFilePathPattern.h"

/// A block function for calculating pattern replacements.
typedef NSString* (^NSStringPatternReplaceBlock) (NSString *group);

/// NSString category providing utility functions.
@interface NSString (IFFilePathPattern)

/// Replace all occurrences of a pattern in a string with another string.
- (NSString *)stringByReplacingPattern:(NSString *)pattern withString:(NSString *)string;
/// Replace all occurrences of a pattern in a string with a replacement calculated from the match.
- (NSString *)stringByReplacingPattern:(NSString *)pattern withBlock:(NSStringPatternReplaceBlock)replaceBlock;
/// Test whether the string matches a pattern.
- (BOOL)stringMatchesPattern:(NSString *)pattern;
/// Return the offset to a sequence within the string; returns -1 if no match.
- (NSUInteger)indexOfString:(NSString *)string;
/// Return an NSRange for the entire string.
- (NSRange)range;

@end

@implementation IFFilePathPattern

static NSMutableDictionary<NSString *, IFMatcherBlock> *IFFilePathPattern_CompiledPatterns;

+ (void)initialize {
    if (!IFFilePathPattern_CompiledPatterns) {
        IFFilePathPattern_CompiledPatterns = [NSMutableDictionary new];
    }
}

+ (IFMatcherBlock)compile:(NSString *)pattern {

    // First check for a previously compiled result.
    IFMatcherBlock result = IFFilePathPattern_CompiledPatterns[pattern];
    if (result) {
        return result;
    }
    
    // An array of pattern variable names.
    NSMutableArray<NSString *> *names = [NSMutableArray new];

    // Convert . to a literal match.
    pattern = [pattern stringByReplacingOccurrencesOfString:@"."
                                                 withString:@"\\."];
    // Match ** followed by / with multiple path components; ^^^ is used as a
    // placeholder for *, which would otherwise be detected on the next replace.
    pattern = [pattern stringByReplacingOccurrencesOfString:@"**/"
                                                 withString:@"(?:[^/]+/)^^^"];
    // Match * to a single path component
    pattern = [pattern stringByReplacingOccurrencesOfString:@"*"
                                                 withString:@"[^/]+"];
    // Convert capturing parenthesis into non-capturing
    pattern = [pattern stringByReplacingPattern:@"\\((?!\\?:)"
                                     withString:@"(?:"];
    // Convert variable placeholders into capturing parens, and record names.
    pattern = [pattern stringByReplacingPattern:@"\\{([^}]+)\\}" withBlock: ^(NSString *group ) {
        // If the matched group looks like a quanfier e.g. {2,3} then return
        // unchanged.
        if ([group stringMatchesPattern:@"^\\d+(,\\d+)?$"]) {
            return [NSString stringWithFormat:@"{%@}", group];
        }
        NSString *name, *pattern;
        // Check if the matched group includes a matching pattern.
        NSUInteger idx = [group indexOfString:@":"];
        if (idx > 0) {
            name = [group substringToIndex:idx];
            pattern = [NSString stringWithFormat:@"(%@)", [group substringFromIndex:idx + 1]];
        }
        else {
            name = group;
            pattern = @"([^/]+)";
        }
        // Record name and return replacement.
        [names addObject:name];
        return pattern;
    }];
    // Replace the ^^^ placeholder with *
    pattern = [pattern stringByReplacingOccurrencesOfString:@"^^^"
                                                 withString:@"*"];

    // Create regex from the pattern.
    pattern = [NSString stringWithFormat:@"^%@$", pattern];
    // Compile the regex here to ensure it is valid  (note that NSRegularExpression isn't thread safe,
    // so we will re-compile it each time it is used).
    NSError *error;
    [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        [NSException raise:@"IFBadFilePathPattern" format:@"%@", [error localizedDescription]];
    }
    
    // Create a block for matching paths.
    IFMatcherBlock matcher = ^(NSString *path) {
        NSMutableDictionary *data = nil;
        // Compile the regex pattern.
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                       options:0
                                                                         error:nil];
        // Execute the regex.
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:path
                                                                  options:0
                                                                    range:[path range]];
        if ([matches count] > 0) {
            data = [NSMutableDictionary new];
            NSTextCheckingResult *result = matches[0];
            // Check there is one more group result than names (first group result is the entire match).
            if ([result numberOfRanges] - 1 != [names count]) {
                // Shouldn't happen...
                [NSException raise:@"IFBadFilePathPattern"
                            format:@"Number of captured groups (%lu) doesn't match expected number of names (%lu)",
                                (unsigned long)[result numberOfRanges] - 1,
                                (unsigned long)[names count]];
            }
            // We will have one name for each matching group in the regex result.
            // Iterate over each name, extract the corresponding value and plug into the result.
            for (NSUInteger idx = 0; idx < [names count]; idx++ ) {
                NSString *name = names[idx];
                NSRange range = [result rangeAtIndex:idx + 1];
                if (range.location != NSNotFound) {
                    NSString *value = [path substringWithRange:range];
                    data[name] = value;
                }
            }
        }
        return data;
    };
    
    // Cache the result.
    IFFilePathPattern_CompiledPatterns[pattern] = matcher;

    // Return the result.
    return matcher;
}

+ (NSDictionary *)matchPath:(NSString *)path usingPattern:(NSString *)pattern {
    IFMatcherBlock matcher = [IFFilePathPattern compile:pattern];
    if (matcher) {
        return matcher( path );
    }
    return nil;
}

@end

@implementation NSString (IFFilePathPattern)

- (NSString *)stringByReplacingPattern:(NSString *)pattern withString:(NSString *)string {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                        options:0
                                                                          error:nil];
    return [re stringByReplacingMatchesInString:self
                                        options:0
                                          range:[self range]
                                      withTemplate:string];
}

- (NSString *)stringByReplacingPattern:(NSString *)pattern withBlock:(NSStringPatternReplaceBlock)replaceBlock {
    // The string result.
    NSMutableString *result = [NSMutableString new];
    // The regex.
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                        options:0
                                                                          error:nil];
    // Execute the regex.
    NSArray<NSTextCheckingResult *> *matches = [re matchesInString:self
                                                           options:0
                                                             range:[self range]];
    // Process the matches.
    NSUInteger idx = 0;
    for (NSTextCheckingResult *match in matches) {
        // Get the match range (this is the substring matching the entire pattern).
        NSRange range = match.range;
        // Copy the portion of the string before the match to the result.
        [result appendString:[self substringWithRange:NSMakeRange(idx, range.location - idx)]];
        // Process and append the matching group (this is the substring matching the first
        // capturing group within the regex).
        [result appendString:replaceBlock([self substringWithRange:[match rangeAtIndex:1]])];
        // Update the start index.
        idx = range.location + range.length;
    }
    // Append the portion of the string after the last match.
    NSUInteger trailing = [self length] - idx;
    if (trailing > 0) {
        [result appendString:[self substringWithRange:NSMakeRange(idx, trailing)]];
    }
    // Return the result.
    return result;
}

- (BOOL)stringMatchesPattern:(NSString *)pattern {
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                        options:0
                                                                          error:nil];
    return [re numberOfMatchesInString:self options:0 range:[self range]] > 0;
}

- (NSUInteger)indexOfString:(NSString *)string {
    NSRange range = [self rangeOfString:string];
    if (range.length == [string length]) {
        return range.location;
    }
    return -1;
}

- (NSRange)range {
    return NSMakeRange(0, [self length]);
}

@end
