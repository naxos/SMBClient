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

#import "SMBShare.h"
#import "SMBFile_Protected.h"
#import "SMBFileServer_Protected.h"

#import "smb_session.h"

@interface SMBStat : NSObject

@property (nonatomic, readonly) BOOL exists;
@property (nonatomic, readonly, getter=isDirectory) BOOL directory;
@property (nonatomic, readonly) unsigned long long size;
@property (nonatomic, readonly, nullable) NSDate *creationTime;
@property (nonatomic, readonly, nullable) NSDate *modificationTime;
@property (nonatomic, readonly, nullable) NSDate *accessTime;
@property (nonatomic, readonly, nullable) NSDate *writeTime;
@property (nonatomic, readonly, nullable) NSDate *statTime;
@property (nonatomic, readonly, nullable) NSString *smbName;

+ (nullable instancetype)statForNonExistingFile;
+ (nullable instancetype)statForRoot;
+ (nullable instancetype)statWithStat:(nonnull smb_stat)stat;

- (nullable instancetype)initWithStat:(nonnull smb_stat)stat;
- (nullable instancetype)initForRoot;
- (nullable instancetype)initForNonExistingFile;

#pragma mark - Unavailable methods

+ new NS_UNAVAILABLE;
- init NS_UNAVAILABLE;

@end

@interface SMBShare ()

- (nullable instancetype)initWithName:(nonnull NSString *)name server:(nonnull SMBFileServer *)server;

- (void)listFiles:(nonnull NSString *)path filter:(nullable BOOL (^)(SMBFile *_Nonnull file))filter completion:(nullable void (^)(NSArray<SMBFile *> *_Nullable files, NSError *_Nullable error))completion;
- (void)getStatusOfFile:(nonnull NSString *)path completion:(nullable void (^)(SMBStat *_Nullable status, NSError *_Nullable error))completion;
- (void)createDirectory:(nonnull NSString *)path completion:(nullable void (^)(SMBFile *_Nullable file, NSError *_Nullable error))completion;
- (void)createDirectories:(nonnull NSString *)path completion:(nullable void (^)(SMBFile *_Nullable file, NSError *_Nullable error))completion;
- (void)deleteFile:(nonnull NSString *)path completion:(nullable void (^)(NSError *_Nullable error))completion;
- (void)openFile:(nonnull NSString *)path mode:(SMBFileMode)mode completion:(nullable void (^)(SMBFile *_Nullable file, smb_fd fd, NSError *_Nullable error))completion;
- (void)closeFile:(smb_fd)fd path:(nonnull NSString *)path completion:(nullable void (^)(SMBFile *_Nullable file, NSError *_Nullable error))completion;

@end
