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
#import "smb_session.h"

@interface SMBError : NSObject

+ (NSError *)unknownError;
+ (NSError *)hostNotFoundError;
+ (NSError *)noIPAddressError;
+ (NSError *)notConnectedError;
+ (NSError *)notOpenError;
+ (NSError *)notSuchFileOrDirectory;
+ (NSError *)writeError;
+ (NSError *)readError;
+ (NSError *)seekError;
+ (NSError *)dsmError:(int)dsmError session:(smb_session *)session;

#pragma mark - Unavailable methods

+ new NS_UNAVAILABLE;
- init NS_UNAVAILABLE;

@end
