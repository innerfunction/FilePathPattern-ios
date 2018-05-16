//
//  FilePathPatternTests.m
//  Tests
//
//  Created by Julian Goacher on 16/05/2018.
//  Copyright © 2018 InnerFunction Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IFFilePathPattern.h"

@interface FilePathPatternTests : XCTestCase

@end

@implementation FilePathPatternTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
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
 */

- (void)testMatch {
    NSDictionary *matches = [IFFilePathPattern matchPath:@"docs/10-Product List.txt" usingPattern:@"docs/{sort}-{title}.txt"];
    XCTAssertNotNil(matches, @"No match");
    XCTAssertEqualObjects(matches[@"sort"], @"10", @"Incorrect {sort} value");
    XCTAssertEqualObjects(matches[@"title"], @"Product List", @"Incorrect {title} value");
}

- (void)testOptionalMatch {
    NSDictionary *matches = [IFFilePathPattern matchPath:@"docs/Product List.txt" usingPattern:@"docs/({sort}-)?{title}.txt"];
    XCTAssertNotNil(matches, @"No match");
    XCTAssertNil(matches[@"sort"], @"Non-nil {sort} value");
    XCTAssertEqualObjects(matches[@"title"], @"Product List", @"Incorrect {title} value");
}

- (void)testWildcardMatch {
    NSDictionary *matches = [IFFilePathPattern matchPath:@"docs/subdir/Product List.txt" usingPattern:@"docs/*/{title}.txt"];
    XCTAssertNotNil(matches, @"No match");
    XCTAssertEqualObjects(matches[@"title"], @"Product List", @"Incorrect {title} value");
}

- (void)testNestedWildcardMatch {
    NSDictionary *matches = [IFFilePathPattern matchPath:@"docs/deeply/nested/Product List.txt" usingPattern:@"docs/**/{title}.txt"];
    XCTAssertNotNil(matches, @"No match");
    XCTAssertEqualObjects(matches[@"title"], @"Product List", @"Incorrect {title} value");
}

- (void)testVariableWithPatternMatch {
    NSDictionary *matches = [IFFilePathPattern matchPath:@"docs/Product List.json" usingPattern:@"docs/{title}.{ext:txt|json}"];
    XCTAssertNotNil(matches, @"No match");
    XCTAssertEqualObjects(matches[@"title"], @"Product List", @"Incorrect {title} value");
    XCTAssertEqualObjects(matches[@"ext"], @"json", @"Incorrect {ext} value");
}

- (void)testMismatch {
    NSDictionary *matches = [IFFilePathPattern matchPath:@"docs/Product List.docx" usingPattern:@"docs/{title}.{ext:txt|json}"];
    XCTAssertNil(matches, @"Match found");
}

/*
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}
*/
@end
