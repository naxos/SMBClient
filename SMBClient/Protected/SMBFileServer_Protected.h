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

#import "SMBFileServer.h"

#import "smb_session.h"

@interface SMBFileServer ()

@property (nonatomic, assign, readonly, nullable) smb_session *smbSession;

- (void)openShare:(nonnull NSString *)name completion:(nullable void (^)(smb_tid tid, NSError * _Nullable error))completion;
- (void)closeShare:(smb_tid)shareID completion:(nullable void (^)(NSError * _Nullable error))completion;

@end