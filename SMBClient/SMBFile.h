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

#import <Foundation/Foundation.h>

@class SMBShare;

@interface SMBFile : NSObject

typedef NS_OPTIONS(NSUInteger, SMBFileMode) {
    SMBFileModeRead = 1 << 0,
    SMBFileModeWrite = 1 << 1,
    
    SMBFileModeReadWrite = SMBFileModeRead | SMBFileModeWrite
};

@property (nonatomic, readonly, nonnull) SMBShare *share;
@property (nonatomic, readonly, nonnull) NSString *path;
@property (nonatomic, readonly, nonnull) NSString *name;
@property (nonatomic, readonly) BOOL exists;
@property (nonatomic, readonly) BOOL isDirectory;
@property (nonatomic, readonly) unsigned long long size;
@property (nonatomic, readonly, nullable) NSDate *creationTime;
@property (nonatomic, readonly, nullable) NSDate *modificationTime;
@property (nonatomic, readonly, nullable) NSDate *accessTime;
@property (nonatomic, readonly, nullable) NSDate *writeTime;
@property (nonatomic, readonly, nullable) NSDate *statusTime;
@property (nonatomic, readonly) BOOL hasStatus;
@property (nonatomic, readonly, nullable) SMBFile *parent;
@property (nonatomic, readonly) BOOL isOpen;

+ (nullable instancetype)rootOfShare:(nonnull SMBShare *)share;
+ (nullable instancetype)fileWithPath:(nonnull NSString *)path share:(nonnull SMBShare *)share;
+ (nullable instancetype)fileWithPath:(nonnull NSString *)path relativeToFile:(nonnull SMBFile *)file;

- (nullable instancetype)initWithPath:(nonnull NSString *)path share:(nonnull SMBShare *)share;
- (nullable instancetype)initWithPath:(nonnull NSString *)path relativeToFile:(nonnull SMBFile *)file;

- (void)open:(SMBFileMode)mode completion:(nullable void (^)(NSError *_Nullable error))completion;
- (void)close:(nullable void (^)(NSError *_Nullable error))completion;
//- (void)write:(nonnull NSData *)data completion:(nullable void (^)(long bytesWritten, NSError *_Nullable error))completion;
- (void)write:(nonnull NSData *_Nullable (^)(unsigned long long))dataHandler progress:(nullable void (^)(unsigned long long bytesWrittenTotal, long bytesWrittenLast, BOOL complete, NSError *_Nullable error))progress;
- (void)read:(NSUInteger)bufferSize progress:(nullable BOOL (^)(unsigned long long bytesReadTotal, NSData *_Nullable data, BOOL complete, NSError *_Nullable error))progress;
- (void)read:(NSUInteger)bufferSize maxBytes:(unsigned long long)maxBytes progress:(nullable BOOL (^)(unsigned long long bytesReadTotal, NSData *_Nullable data, BOOL complete, NSError *_Nullable error))progress;
- (void)seek:(unsigned long long)offset absolute:(BOOL)absolute completion:(nullable void (^)(unsigned long long position, NSError *_Nullable error))completion;

- (void)listFiles:(nullable void (^)(NSArray<SMBFile *> *_Nullable files, NSError *_Nullable error))completion;
- (void)listFilesUsingFilter:(nullable BOOL (^)(SMBFile *_Nonnull file))filter completion:(nullable void (^)(NSArray<SMBFile *> *_Nullable files, NSError *_Nullable error))completion;
- (void)updateStatus:(nullable void (^)(NSError *_Nullable error))completion;
- (void)createDirectory:(nullable void (^)(NSError *_Nullable error))completion;
- (void)createDirectories:(nullable void (^)(NSError *_Nullable error))completion;
- (void)delete:(nullable void (^)(NSError *_Nullable error))completion;
- (void)moveTo:(nonnull NSString *)path completion:(nullable void (^)(NSError *_Nullable error))completion;

#pragma mark - Unavailable methods

+ new NS_UNAVAILABLE;
- init NS_UNAVAILABLE;

@end
