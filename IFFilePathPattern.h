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

#import <Foundation/Foundation.h>

/**
 * A block function for matching file path strings.
 * Returns a dictionary of match results, or nil if the path doesn't match.
 */
typedef NSDictionary* (^IFMatcherBlock) (NSString *path);

@interface IFFilePathPattern : NSObject

/**
 * Compile a file path pattern into a regex and variable group lookup.
 * Supports a modified version of the standard regex format to allow matching of
 * file path patterns, and extraction of named variable data from paths.
 * The grammar supports the following additional constructs:
 *  .               Match a full stop (i.e. file extension delimiter).
 *  *               Match any file or directory name at the specified position.
 *  **              Match any number of nested directories at the specified position.
 *  {xxx}           Match file name characters and save to a variable named 'xxx'.
 *  {xxx:regex}     Match file name characters conforming to a specific regular expression,
 *                  and save any matches to a variable named 'xxx'.
 *
 * Examples:
 *
 *  docs/{sort}-{title}.txt
 *              Match file paths like 'docs/10-Product List.txt'.
 *  docs/({sort}-)?{title}.txt
 *              As above, but the {sort}- token is optional.
 *  docs\*\{title}.txt (backslash used in path here because * and / ends the comment).
 *              Match *.txt files in all child directories of docs/.
 *  docs\**\{title}.txt
 *              Match *.txt files in all directories under docs/.
 *  docs/{title}.(txt|json|csv)
 *              Match *.txt, *.json or *.csv files under docs/.
 *  docs/{title}.{ext:txt|json|csv}
 *              Like the preceeding example, but the matching file extension is saved
 *              to a variable named 'ext'.
 *
 * The method returns a block function which can be used to match a path string.
 */
+ (IFMatcherBlock)compile:(NSString *)pattern;

/**
 * Attempt to match a file path string against a pattern.
 * Returns a dictionary of match results if the pattern matches, nil otherwise.
 */
+ (NSDictionary *)matchPath:(NSString *)path usingPattern:(NSString *)pattern;

@end
