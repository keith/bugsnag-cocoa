//
//  BugsnagErrorTest.m
//  Tests
//
//  Created by Jamie Lynch on 08/04/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BugsnagKeys.h"
#import "BugsnagError.h"
#import "BugsnagStackframe.h"

NSString *_Nonnull BSGParseErrorClass(NSDictionary *error, NSString *errorType);

NSString *BSGParseErrorMessage(NSDictionary *report, NSDictionary *error, NSString *errorType);

@interface BugsnagError ()
- (instancetype)initWithEvent:(NSDictionary *)event;

- (NSDictionary *)toDictionary;
@end

@interface BugsnagErrorTest : XCTestCase
@property NSDictionary *event;
@end

@implementation BugsnagErrorTest

- (void)setUp {
    NSDictionary *thread = @{
            @"current_thread": @YES,
            @"crashed": @YES,
            @"index": @4,
            @"backtrace": @{
                    @"skipped": @0,
                    @"contents": @[
                            @{
                                    @"symbol_name": @"kscrashsentry_reportUserException",
                                    @"symbol_addr": @4491038467,
                                    @"instruction_addr": @4491038575,
                                    @"object_name": @"CrashProbeiOS",
                                    @"object_addr": @4490747904
                            }
                    ]
            }
    };
    NSDictionary *binaryImage = @{
            @"uuid": @"D0A41830-4FD2-3B02-A23B-0741AD4C7F52",
            @"image_vmaddr": @4294967296,
            @"image_addr": @4490747904,
            @"image_size": @483328,
            @"name": @"/Users/joesmith/foo",
    };
    self.event = @{
            @"crash": @{
                    @"error": @{
                            @"type": @"user",
                            @"user_reported": @{
                                    @"name": @"Foo Exception"
                            },
                            @"reason": @"Foo overload"
                    },
                    @"threads": @[thread],
            },
            @"binary_images": @[binaryImage]
    };
}

- (void)testErrorLoad {
    BugsnagError *error = [[BugsnagError alloc] initWithEvent:self.event];
    XCTAssertEqualObjects(@"Foo Exception", error.errorClass);
    XCTAssertEqualObjects(@"Foo overload", error.errorMessage);
    XCTAssertEqual(BSGErrorTypeCocoa, error.type);

    XCTAssertEqual(1, [error.stacktrace count]);
    BugsnagStackframe *frame = error.stacktrace[0];
    XCTAssertEqualObjects(@"kscrashsentry_reportUserException", frame.method);
    XCTAssertEqualObjects(@"CrashProbeiOS", frame.machoFile);
    XCTAssertEqualObjects(@"D0A41830-4FD2-3B02-A23B-0741AD4C7F52", frame.machoUuid);
}

- (void)testToDictionary {
    BugsnagError *error = [[BugsnagError alloc] initWithEvent:self.event];
    NSDictionary *dict = [error toDictionary];
    XCTAssertEqualObjects(@"Foo Exception", dict[@"errorClass"]);
    XCTAssertEqualObjects(@"Foo overload", dict[@"message"]);
    XCTAssertEqualObjects(@"cocoa", dict[@"type"]);

    XCTAssertEqual(1, [dict[@"exceptions"] count]);
    NSDictionary *frame = dict[@"exceptions"][0];
    XCTAssertEqualObjects(@"kscrashsentry_reportUserException", frame[@"method"]);
    XCTAssertEqualObjects(@"D0A41830-4FD2-3B02-A23B-0741AD4C7F52", frame[@"machoUUID"]);
    XCTAssertEqualObjects(@"CrashProbeiOS", frame[@"machoFile"]);
}

- (void)testErrorClassParse {
    XCTAssertEqualObjects(@"foo", BSGParseErrorClass(@{@"cpp_exception": @{@"name": @"foo"}}, @"cpp_exception"));
    XCTAssertEqualObjects(@"bar", BSGParseErrorClass(@{@"mach": @{@"exception_name": @"bar"}}, @"mach"));
    XCTAssertEqualObjects(@"wham", BSGParseErrorClass(@{@"signal": @{@"name": @"wham"}}, @"signal"));
    XCTAssertEqualObjects(@"zed", BSGParseErrorClass(@{@"nsexception": @{@"name": @"zed"}}, @"nsexception"));
    XCTAssertEqualObjects(@"ooh", BSGParseErrorClass(@{@"user_reported": @{@"name": @"ooh"}}, @"user"));
    XCTAssertEqualObjects(@"Exception", BSGParseErrorClass(@{}, @"some-val"));
}

- (void)testErrorMessageParse {
    XCTAssertEqualObjects(@"", BSGParseErrorMessage(@{}, @{}, @""));
    XCTAssertEqualObjects(@"foo", BSGParseErrorMessage(@{}, @{@"reason": @"foo"}, @""));

    XCTAssertEqualObjects(@"Exception", BSGParseErrorMessage(@{
            @"crash": @{
                    @"diagnosis": @"Exception"
            }
    }, @{}, @"signal"));

    XCTAssertEqualObjects(@"Exceptional circumstance", BSGParseErrorMessage(@{
            @"crash": @{
                    @"diagnosis": @"Exceptional circumstance\ntest"
            }
    }, @{}, @"mach"));

    XCTAssertEqualObjects(@"", BSGParseErrorMessage(@{
            @"crash": @{
                    @"diagnosis": @"No diagnosis foo"
            }
    }, @{}, @"mach"));
}

@end
