// -----------------------------------------------------------------------------
// This file is part of SMBClient.
// Copyright © 2016 Naxos Software Solutions GmbH.
//
// Author: Martin Schaefer <martin.schaefer@naxos-software.de>
//
// SMBClient is licensed under the GNU Lesser General Public License version 2.1
// or later
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

#import "SMBShare_Protected.h"
#import "SMBError.h"
#import "SMBFile_Protected.h"

#import "smb_share.h"
#import "smb_dir.h"
#import "smb_file.h"
#import "smb_stat.h"

@interface SMBShare ()

@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic) smb_tid shareID;

@end

@implementation SMBShare

- (nullable instancetype)initWithName:(nonnull NSString *)name server:(nonnull SMBFileServer *)server {
    self = [super init];
    if (self) {
        NSString *queueName = [NSString stringWithFormat:@"smb_share_queue_%@", name];

        _name = name;
        _server = server;
        _shareID = 0;
        _serialQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    smb_tree_disconnect(_server.smbSession, _shareID);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ on %@", self.name, self.server];
}

- (void)open:(nullable void (^)(NSError *_Nullable))completion {
    dispatch_async(_serialQueue, ^{
        [self.server openShare:self.name completion:^(smb_tid shareID, NSError *error){
            if (error == nil) {
                _shareID = shareID;
            }
            if (completion) {
                completion(error);
            }
        }];
    });
}

- (void)close:(nullable void (^)(NSError *_Nullable))completion {
    dispatch_async(_serialQueue, ^{
        if (_shareID == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([SMBError notOpenError]);
            });
        } else {
            [self.server closeShare:_shareID completion:completion];
            _shareID = 0;
        }
    });
}

- (BOOL)isOpen {
    return _shareID > 0;
}

- (void)createDirectories:(nonnull NSString *)path completion:(nullable void (^)(SMBFile *_Nullable, NSError *_Nullable))completion {
    dispatch_async(_serialQueue, ^{
        SMBFile *file = nil;
        NSError *error = nil;
        
        if (self.server.smbSession) {
            if ([self isOpen]) {
                NSString *p = path;
                
                while ([p hasPrefix:@"/"]) {
                    p = [path substringFromIndex:1];
                }
                NSArray *directories = p.pathComponents;
                
                p = @"";
                
                for (NSUInteger i = 0; error == nil && i < directories.count; i++) {
                    p = [p stringByAppendingFormat:@"\\%@", [directories objectAtIndex:i]];
                    
                    const char *cpath = p.UTF8String;
                    smb_stat stat = [self _stat:cpath];
                    
                    if (stat == NULL) {
                        int dsm_error = smb_directory_create(self.server.smbSession, _shareID, cpath);
                        
                        if (dsm_error != 0) {
                            error = [SMBError dsmError:dsm_error session:self.server.smbSession];
                        }
                    }
                    
                    if (error == nil && i == directories.count - 1) {
                        file = [[SMBFile alloc] initWithPath:path share:self];
                        
                        if (stat == NULL) {
                            stat = [self _stat:cpath];
                        }
                        
                        if (stat != NULL) {
                            file.smbStat = [[SMBStat alloc] initWithStat:stat];
                        } else {
                            // shouldn't really happen, because we just created this directory
                            file.smbStat = [SMBStat statForNonExistingFile];
                        }
                    }
                    
                    if (stat != NULL) {
                        smb_stat_destroy(stat);
                    }
                }
                
            } else {
                error = [SMBError notOpenError];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(file, error);
            });
        }
    });
}

- (void)createDirectory:(nonnull NSString *)path completion:(nullable void (^)(SMBFile *_Nullable, NSError *_Nullable))completion {
    dispatch_async(_serialQueue, ^{
        SMBFile *file = nil;
        NSError *error = nil;
        
        if (self.server.smbSession) {
            if ([self isOpen]) {
                
                NSString *smbPath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
                const char *cpath = smbPath.UTF8String;
                smb_stat stat = [self _stat:cpath];
                
                if (stat == NULL) {
                    int dsm_error = smb_directory_create(self.server.smbSession, _shareID, cpath);
                    
                    if (dsm_error != 0) {
                        error = [SMBError dsmError:dsm_error session:self.server.smbSession];
                    }
                }
                
                if (error == nil) {
                    file = [[SMBFile alloc] initWithPath:path share:self];
                    
                    if (stat == NULL) {
                        stat = [self _stat:cpath];
                    }
                    
                    if (stat != NULL) {
                        file.smbStat = [[SMBStat alloc] initWithStat:stat];
                    } else {
                        // shouldn't really happen, because we just created this directory
                        file.smbStat = [SMBStat statForNonExistingFile];
                    }
                }
                
                if (stat != NULL) {
                    smb_stat_destroy(stat);
                }
            } else {
                error = [SMBError notOpenError];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(file, error);
            });
        }
    });
}

- (uint32_t)_mod:(SMBFileMode)mode {
    uint32_t mod = 0;
    
    if (mode & SMBFileModeRead) {
        mod |= SMB_MOD_READ | SMB_MOD_READ_EXT | SMB_MOD_READ_ATTR | SMB_MOD_READ_CTL;
    }
    if (mode & SMBFileModeWrite) {
        mod |= SMB_MOD_WRITE | SMB_MOD_WRITE_EXT | SMB_MOD_WRITE_ATTR | SMB_MOD_APPEND;
    }

    return mod;
}

- (void)openFile:(nonnull NSString *)path mode:(SMBFileMode)mode completion:(nullable void (^)(SMBFile *, smb_fd, NSError *_Nullable))completion {

    dispatch_async(_serialQueue, ^{

        smb_fd fd = -1;
        NSError *error = nil;
        SMBFile *file = nil;
        
        if (self.server.smbSession) {
            if ([self isOpen]) {
                NSString *smbPath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
                const char *cpath = smbPath.UTF8String;
                uint32_t mod = [self _mod:mode];
                smb_stat stat = [self _stat:cpath];

                file = [[SMBFile alloc] initWithPath:path share:self];

                if (stat != NULL) {
                    file.smbStat = [[SMBStat alloc] initWithStat:stat];
                } else {
                    file.smbStat = [SMBStat statForNonExistingFile];
                }

                int dsm_error = smb_fopen(self.server.smbSession, self.shareID, cpath, mod, &fd);
                
                if (dsm_error != 0) {
                    error = [SMBError dsmError:dsm_error session:self.server.smbSession];
                }
            } else {
                error = [SMBError notOpenError];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(file, fd, error);
            });
        }
    });
}

- (void)closeFile:(smb_fd)fd path:(NSString *)path completion:(nullable void (^)(SMBFile *_Nullable, NSError *_Nullable))completion {

    dispatch_async(_serialQueue, ^{

        NSError *error = nil;
        SMBFile *file = nil;
        
        if (self.server.smbSession) {
            if ([self isOpen]) {
                
                smb_fclose(self.server.smbSession, fd);
                
                NSString *smbPath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
                const char *cpath = smbPath.UTF8String;
                smb_stat stat = [self _stat:cpath];
                
                file = [[SMBFile alloc] initWithPath:path share:self];
                
                if (stat != NULL) {
                    file.smbStat = [[SMBStat alloc] initWithStat:stat];
                } else {
                    file.smbStat = [SMBStat statForNonExistingFile];
                }

            } else {
                error = [SMBError notOpenError];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(file, error);
            });
        }
    });
}

- (void)deleteFile:(nonnull NSString *)path completion:(nullable void (^)(NSError *_Nullable))completion {
    dispatch_async(_serialQueue, ^{
        NSError *error = nil;
        
        if (self.server.smbSession) {
            if ([self isOpen]) {
                
                NSString *smbPath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
                const char *cpath = smbPath.UTF8String;
                smb_stat stat = [self _stat:cpath];
                
                if (stat != NULL) {
                    int dsm_error = 0;
                    
                    if (smb_stat_get(stat, SMB_STAT_ISDIR) != 0) {
                        dsm_error = smb_directory_rm(self.server.smbSession, _shareID, cpath);
                    } else {
                        dsm_error = smb_file_rm(self.server.smbSession, _shareID, cpath);
                    }

                    if (dsm_error != 0) {
                        error = [SMBError dsmError:dsm_error session:self.server.smbSession];
                    }
                    
                    smb_stat_destroy(stat);
                }
                
            } else {
                error = [SMBError notOpenError];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }
    });
}

- (void)listFiles:(void (^)(NSArray<SMBFile *> *, NSError *))completion {
    [self listFiles:@"/" filter:nil completion:completion];
}

- (void)listFilesUsingFilter:(nullable BOOL (^)(SMBFile *_Nonnull))filter completion:(void (^)(NSArray<SMBFile *> *, NSError *))completion {
    [self listFiles:@"/" filter:filter completion:completion];
}

- (void)listFiles:(NSString *)path filter:(nullable BOOL (^)(SMBFile *_Nonnull file))filter completion:(void (^)(NSArray<SMBFile *> *, NSError *))completion {
    
    dispatch_async(_serialQueue, ^{
        
        NSMutableArray *fileList = nil;
        NSError *error = nil;
        
        if (self.server.smbSession) {
            if ([self isOpen]) {
                
                NSString *smbPath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
                
                if (![smbPath hasSuffix:@"\\"]) {
                    smbPath = [smbPath stringByAppendingString:@"\\"];
                }
                smbPath = [smbPath stringByAppendingString:@"*"];
                
                //Query for a list of files in this directory
                smb_stat_list statList = smb_find(self.server.smbSession, _shareID, smbPath.UTF8String);
                
                if (statList != NULL) {
                    size_t listCount = smb_stat_list_count(statList);
                    
                    fileList = [NSMutableArray array];
                    
                    for (NSInteger i = 0; i < listCount; i++) {
                        smb_stat item = smb_stat_list_at(statList, i);
                        const char *name = smb_stat_name(item);
                        
                        NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithUTF8String:name]];
                        
                        SMBFile *file = [[SMBFile alloc] initWithPath:filePath share:self];
                        
                        file.smbStat = [[SMBStat alloc] initWithStat:item];
                        
                        if (!(file.isDirectory && ([file.name isEqualToString:@".."] || [file.name isEqualToString:@"."]))) {
                            if (filter == nil || filter(file)) {
                                [fileList addObject:file];
                            }
                        }
                    }
                    smb_stat_list_destroy(statList);
                }
                
            } else {
                error = [SMBError notOpenError];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(fileList, error);
            });
        }
    });
}

- (void)getStatusOfFile:(NSString *)path completion:(void (^)(SMBStat *, NSError *))completion {

    if (path.length == 0 || [path isEqualToString:@"/"]) {
        if (completion) {
            completion([SMBStat statForRoot], nil);
        }
    } else {
        dispatch_async(_serialQueue, ^{
            NSError *error = nil;
            SMBStat *smbStat = nil;
            
            if (self.server.smbSession) {
                
                if ([self isOpen]) {
                    NSString *smbPath = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
                    smb_stat stat = [self _stat:smbPath.UTF8String];
                    
                    if (stat != NULL) {
                        smbStat = [SMBStat statWithStat:stat];
                        
                        smb_stat_destroy(stat);
                    } else {
                        smbStat = [SMBStat statForNonExistingFile];
                    }
                    
                } else {
                    error = [SMBError notOpenError];
                }
            } else {
                error = [SMBError notConnectedError];
            }
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(smbStat, error);
                });
            }
        });
    }    
}

#pragma mark - Private methods

- (smb_stat)_stat:(const char *)path {
    smb_stat stat = smb_fstat(self.server.smbSession, _shareID, path);
    
    // This is a workaround because the above doesn't seem to work on directories
    // See https://github.com/videolabs/libdsm/issues/79
    
    if (stat == NULL) {
        smb_stat_list statList = smb_find(self.server.smbSession, _shareID, path);
        
        if (statList != NULL) {
            size_t listCount = smb_stat_list_count(statList);
            
            if (listCount == 1) {
                stat = smb_stat_list_at(statList, 0);
            } else {
                NSLog(@"Unexpectedly got multiple stat entries for %s", path);
            }
        }
    }
    // end of workaround
    
    return stat;
}

@end

@implementation SMBStat

+ (nullable instancetype)statForNonExistingFile {
    return [[self alloc] initForNonExistingFile];
}

+ (nullable instancetype)statForRoot {
    return [[self alloc] initForRoot];
}

+ (nullable instancetype)statWithStat:(smb_stat)stat {
    return [[self alloc] initWithStat:stat];
}

- (nullable instancetype)initForNonExistingFile {
    self = [super init];
    if (self) {
        _statTime = [NSDate new];
    }
    return self;
}

- (instancetype)initForRoot {
    self = [super init];
    if (self) {
        _directory = YES;
        _exists = YES;
        _statTime = [NSDate new];
        _smbName = @"\\";
    }
    return self;
}

- (instancetype)initWithStat:(smb_stat)stat {
    self = [super init];
    if (self) {
        if (stat != NULL) {
            uint64_t modificationTimestamp = smb_stat_get(stat, SMB_STAT_MTIME);
            uint64_t creationTimestamp = smb_stat_get(stat, SMB_STAT_CTIME);
            uint64_t accessTimestamp = smb_stat_get(stat, SMB_STAT_ATIME);
            uint64_t writeTimestamp = smb_stat_get(stat, SMB_STAT_WTIME);
            
            _smbName = [NSString stringWithUTF8String:smb_stat_name(stat)];
            
            _size = smb_stat_get(stat, SMB_STAT_SIZE);
            _directory = (smb_stat_get(stat, SMB_STAT_ISDIR) != 0);
            
            _modificationTime = [self _dateFromSMBTime:modificationTimestamp];
            _creationTime = [self _dateFromSMBTime:creationTimestamp];
            _accessTime = [self _dateFromSMBTime:accessTimestamp];
            _writeTime = [self _dateFromSMBTime:writeTimestamp];
            
            _exists = YES;
        }
        
        _statTime = [NSDate new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Status of %@ %@ as of %@: Size: %llu, Created: %@, Modified: %@, Last opened: %@", self.isDirectory ? @"directory" : @"file", self.smbName, self.statTime, self.size, self.creationTime, self.modificationTime, self.accessTime];
}

#pragma mark - Private methods

- (NSDate *)_dateFromSMBTime:(uint64_t)smbTime {
    // If you really want some explanation, search for
    // 'SystemTimeLow and SystemTimeHigh' at http://ubiqx.org/cifs/SMB.html
    
    NSTimeInterval timestamp  = (NSTimeInterval)((smbTime/10000000.) - 11644473600);
    
    return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

@end
