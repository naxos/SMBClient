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

#import "SMBDevice.h"
#import "SMBShare.h"

@interface SMBFileServer : SMBDevice

- (nullable instancetype)initWithHost:(nonnull NSString *)ipAddressOrHostname netbiosName:(nonnull NSString *)name group:(nullable NSString *)group;

- (void)disconnect:(nullable void (^)(void))completion;
- (void)connectAsUser:(nullable NSString *)username password:(nullable NSString *)password completion:(nullable void (^)(BOOL guest, NSError *_Nullable error))completion;
- (void)listShares:(nullable void (^)(NSArray<SMBShare *> *_Nullable shares, NSError *_Nullable error))completion;
- (void)findShare:(nonnull NSString *)name completion:(nullable void (^)(SMBShare *_Nullable share, NSError *_Nullable error))completion;

#pragma mark - Unavailable methods

+ new NS_UNAVAILABLE;
- init NS_UNAVAILABLE;

@end
