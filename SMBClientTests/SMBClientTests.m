// -----------------------------------------------------------------------------
// This file is part of SMBClient.
// Copyright © 2016 Naxos Software Solutions GmbH.
//
// Author: Martin Schaefer <martin.schaefer@naxos-software.de>
//
// SMBClient is dual-licensed under both the MIT License, and the
// LGPL v2.1 (or later) License.
// -----------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
// -----------------------------------------------------------------------------

#import <XCTest/XCTest.h>

#import "SMBDiscovery.h"
#import "SMBFileServer.h"
#import "SMBFile.h"


// netbios name, ip address or hostname of the server
static NSString *host = @"192.168.178.56";
// name of a share on the server
static NSString *fileShare = @"Guest Share";
// credentials of a user with write access to the share,
// nil (or anything invalid) for guest access (if available)
static NSString *username = nil;
static NSString *password = nil;


@interface SMBClientTests : XCTestCase

@end

@implementation SMBClientTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test {
    
    // ----------------- Discovery ----------------- //
    
    XCTestExpectation *discoveryExpectation = [self expectationWithDescription:@"Discovery"];
    
    __block SMBFileServer *server = nil;
    
    BOOL ok = [[SMBDiscovery sharedInstance] startDiscoveryOfType:SMBDeviceTypeFileServer added:^(SMBDevice *device) {
        NSLog(@"Device added: %@", device);
        
        if ([device.netbiosName isEqualToString:host] || [device.host isEqualToString:host]) {
            server = (SMBFileServer *)device;
            
            [discoveryExpectation fulfill];
        }
    } removed:nil];
    
    XCTAssert(ok, @"Discovery not started");
    
    NSLog(@"Discovery running...");
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssert(server != nil, @"Server '%@' not found", host);
    
    // ----------------- Connection ----------------- //
    
    if (server) {
        XCTestExpectation *connectExpectation = [self expectationWithDescription:@"Connection"];
        
        [server connectAsUser:username password:password completion:^(BOOL guest, NSError *error) {
            
            [connectExpectation fulfill];
            
            XCTAssert(error == nil, @"Error: %@", error);
            
            NSLog(@"Connected to %@", server);
            
            if (guest) {
                NSLog(@"Logged in as guest");
            }
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
        
        // ----------------- List shares ----------------- //
        
        XCTestExpectation *sharesExpectation = [self expectationWithDescription:@"List shares"];
        
        __block NSArray<SMBShare *> *shares = nil;
        
        [server listShares:^(NSArray<SMBShare *> *shareList, NSError *error) {
            [sharesExpectation fulfill];
            
            XCTAssert(error == nil, @"Error: %@", error);
            
            shares = shareList;
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
        
        // ----------------- List files ----------------- //
        
        SMBShare *testShare = nil;
        
        for (SMBShare *share in shares) {
            NSLog(@"Got share: %@", share.name);
            
            if ([share.name isEqualToString:fileShare]) {
                testShare = share;
            }
            
            XCTestExpectation *filesExpectation = [self expectationWithDescription:@"List files"];
            
            [share open:^(NSError *error) {
                XCTAssert(error == nil, @"Error: %@", error);
                
                /* An alternative for the next line of code
                 SMBFile *root = [SMBFile rootOfShare:share];
                 [root listFiles:^(NSArray<SMBFile *> *files, NSError *error) {
                 */
                
                [share listFiles:^(NSArray<SMBFile *> *files, NSError *error) {
                    [filesExpectation fulfill];
                    
                    XCTAssert(error == nil, @"Error: %@", error);
                    
                    for (SMBFile *file in files) {
                        NSLog(@"  Got %@: %@", file.isDirectory ? @"dir" : @"file", file.path);
                    }
                }];
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
        }
        
        XCTAssert(testShare != nil, @"Test share '%@' not found", fileShare);
        
        if (testShare) {
            
            // ----------------- Create directory ----------------- //
            
            XCTestExpectation *createDirExpectation = [self expectationWithDescription:@"Create directory"];
            
            SMBFile *dir = [[SMBFile alloc] initWithPath:@"/abcd" share:testShare];
            
            [dir createDirectory:^(NSError *error) {
                [createDirExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
                
                if (error == nil) {
                    XCTAssert(dir.exists, @"File %@ does not exist", dir.path);
                    
                    XCTAssert(dir.isDirectory, @"File %@ is NOT a directory", dir.path);
                    
                    if (dir.exists) {
                        if (dir.isDirectory) {
                            NSLog(@"Directory created: %@", dir);
                        }
                    }
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- Delete directory ----------------- //
            
            XCTestExpectation *deleteDirExpectation = [self expectationWithDescription:@"Delete directory"];
            
            [dir delete:^(NSError *error) {
                [deleteDirExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
                
                if (error == nil) {
                    XCTAssert(!dir.exists, @"Directory %@ still exists", dir.path);
                    
                    if (!dir.exists) {
                        NSLog(@"Directory %@ deleted", dir.path);
                    }
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- Create directories ----------------- //
            
            XCTestExpectation *createDirsExpectation = [self expectationWithDescription:@"Create directories"];
            
            SMBFile *dirs = [[SMBFile alloc] initWithPath:@"/a/b/c/d" share:testShare];
            
            [dirs createDirectories:^(NSError *error) {
                [createDirsExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
                
                if (error == nil) {
                    XCTAssert(dirs.exists, @"File %@ does not exist", dirs.path);
                    
                    XCTAssert(dirs.isDirectory, @"%@ is not a directory", dirs.path);
                    
                    if (dirs.exists) {
                        if (dirs.isDirectory) {
                            NSLog(@"Directories created: %@", dirs.path);
                        }
                    }
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- File write ----------------- //
            
            XCTestExpectation *writeExpectation = [self expectationWithDescription:@"File write"];
            
            SMBFile *file = [[SMBFile alloc] initWithPath:@"/a/test.txt" share:testShare];
            
            [file open:SMBFileModeReadWrite completion:^(NSError *error) {
                XCTAssert(error == nil, @"Error: %@", error);
                
                if (error == nil) {
                    
                    NSData *data = [@"Hello world!\n" dataUsingEncoding:NSUTF8StringEncoding];
                    
                    [file write:^NSData *(unsigned long long offset) {
                        if (offset < data.length) {
                            return [data subdataWithRange:NSMakeRange(offset, MIN(4, data.length - offset))];
                        } else {
                            return nil;
                        }
                    } progress:^(unsigned long long bytesWrittenTotal, long bytesWrittenLast, BOOL complete, NSError *error) {
                        XCTAssert(error == nil, @"Error: %@", error);
                        
                        NSLog(@"Wrote %ld bytes, in total %llu bytes (%0.2f %%)", bytesWrittenLast, bytesWrittenTotal, (double)bytesWrittenTotal / data.length * 100);
                        
                        if (complete) {
                            
                            [file close:^(NSError *error) {
                                [writeExpectation fulfill];
                                
                                XCTAssert(error == nil, @"Error: %@", error);
                                
                                NSLog(@"File size: %llu bytes", file.size);
                                
                                XCTAssert(file.size == data.length, @"Unexcpected file size");
                                
                            }];
                        }
                    }];
                } else {
                    [writeExpectation fulfill];
                }
            }];
            
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            
            // ----------------- File read ----------------- //
            
            XCTestExpectation *readExpectation = [self expectationWithDescription:@"File read"];
            
            [file open:SMBFileModeRead completion:^(NSError *error) {
                XCTAssert(error == nil, @"Error: %@", error);
                
                if (error == nil) {
                    
                    NSMutableData *result = [NSMutableData new];
                    
                    [file read:3 progress:^(unsigned long long bytesReadTotal, NSData * _Nullable data, BOOL complete, NSError * _Nullable error) {
                        
                        XCTAssert(error == nil, @"Error: %@", error);
                        
                        NSLog(@"Read %ld bytes, in total %llu bytes (%0.2f %%)", data.length, bytesReadTotal, (double)bytesReadTotal / file.size * 100);
                        
                        if (data) {
                            [result appendData:data];
                        }
                        
                        if (complete) {
                            
                            NSString *s = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                            
                            XCTAssert([s isEqualToString:@"Hello world!\n"], @"Unexpected result");
                            
                            NSLog(@"Result: %@", s);
                            
                            [file close:^(NSError *error) {
                                [readExpectation fulfill];
                                
                                XCTAssert(error == nil, @"Error: %@", error);
                            }];
                        }
                        
                    }];
                    
                } else {
                    [readExpectation fulfill];
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            
            // ----------------- File status ----------------- //
            
            XCTestExpectation *statusExpectation = [self expectationWithDescription:@"File status"];
            
            file = [[SMBFile alloc] initWithPath:@"/a/test.txt" share:testShare];
            
            [file updateStatus:^(NSError *error) {
                [statusExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
                
                if (error == nil) {
                    XCTAssert(file.exists, @"File %@ does not exist", file.path);
                    
                    if (file.exists) {
                        NSLog(@"%@", file);
                        if (file.isDirectory) {
                            NSLog(@"File %@ is a directory", file.path);
                        } else {
                            NSLog(@"File %@", file.path);
                            NSLog(@"Size: %llu", file.size);
                            NSLog(@"Created: %@", file.creationTime);
                            NSLog(@"Modified: %@", file.modificationTime);
                            NSLog(@"Last opened: %@", file.accessTime);
                        }
                    }
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- File filter ----------------- //
            
            XCTestExpectation *filterExpectation = [self expectationWithDescription:@"File filter"];
            NSString *fileName = @"a";
            
            [testShare listFilesUsingFilter:^BOOL(SMBFile * _Nonnull file) {
                return [file.name isEqualToString:fileName];
            } completion:^(NSArray<SMBFile *> * _Nullable files, NSError * _Nullable error) {
                [filterExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
                
                XCTAssert(files.count == 1, @"%lu files found, expecting 1", files.count);
                
                if (files.count == 1) {
                    
                    NSLog(@"File found: %@", files.firstObject);
                    
                    XCTAssert([files.firstObject.name isEqualToString:fileName], @"Expected file name to be %@", fileName);
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- File filter 2 ----------------- //
            
            filterExpectation = [self expectationWithDescription:@"File filter 2"];
            
            fileName = @"test.txt";
            
            file = [[SMBFile alloc] initWithPath:@"/a" share:testShare];
            
            [file listFilesUsingFilter:^BOOL(SMBFile * _Nonnull file) {
                return [file.name isEqualToString:fileName];
            } completion:^(NSArray<SMBFile *> * _Nullable files, NSError * _Nullable error) {
                [filterExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
                
                XCTAssert(files.count == 1, @"%lu files found, expecting 1", files.count);
                
                if (files.count == 1) {
                    
                    NSLog(@"File found: %@", files.firstObject);
                    
                    XCTAssert([files.firstObject.name isEqualToString:fileName], @"Expected file name to be %@", fileName);
                }
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- Delete file ----------------- //
            
            XCTestExpectation *deleteFileExpectation = [self expectationWithDescription:@"Delete file"];
            
            file = [[SMBFile alloc] initWithPath:@"/a/test.txt" share:testShare];
            
            [file updateStatus:^(NSError * _Nullable error) {
                XCTAssert(error == nil, @"Error: %@", error);
                
                XCTAssert(file.exists, @"File does not exist");
                
                [file delete:^(NSError * _Nullable error) {
                    [deleteFileExpectation fulfill];
                    
                    XCTAssert(error == nil, @"Error: %@", error);
                    
                    XCTAssert(file.exists == NO, @"Status incorrect");
                }];
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
            // ----------------- Delete dirs ----------------- //
            
            XCTestExpectation *deleteDirsExpectation = [self expectationWithDescription:@"Delete dirs"];
            
            file = [[SMBFile alloc] initWithPath:@"/a/b/c/d" share:testShare];
            
            [file delete:^(NSError * _Nullable error) {
                XCTAssert(error == nil, @"Error: %@", error);
                
                [file.parent delete:^(NSError * _Nullable error) {
                    XCTAssert(error == nil, @"Error: %@", error);
                    
                    [file.parent.parent delete:^(NSError * _Nullable error) {
                        XCTAssert(error == nil, @"Error: %@", error);
                        
                        [file.parent.parent.parent delete:^(NSError * _Nullable error) {
                            [deleteDirsExpectation fulfill];
                            
                            XCTAssert(error == nil, @"Error: %@", error);
                        }];
                    }];
                }];
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
            
        } // end if (testShare)
        
        // ----------------- Close shares ----------------- //
        
        for (SMBShare *share in shares) {
            XCTestExpectation *closeExpectation = [self expectationWithDescription:@"Close share"];
            
            [share close:^(NSError *error) {
                [closeExpectation fulfill];
                
                XCTAssert(error == nil, @"Error: %@", error);
            }];
            
            [self waitForExpectationsWithTimeout:5.0 handler:nil];
        }
        
        // ----------------- Disconnect ----------------- //
        
        XCTestExpectation *diconnectExpectation = [self expectationWithDescription:@"Disconnect"];
        
        [server disconnect:^() {
            NSLog(@"Disconnected from %@", server);
            
            [diconnectExpectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5.0 handler:nil];
        
    }  // end if (server)
}

@end
