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

#import "SMBError.h"

@implementation SMBError

+ (NSError *)unknownError {
    return [NSError errorWithDomain:@"smb.error" code:50 userInfo:@{ NSLocalizedDescriptionKey : @"Unknown error"} ];
}

+ (NSError *)hostNotFoundError {
    return [NSError errorWithDomain:@"smb.error" code:51 userInfo:@{ NSLocalizedDescriptionKey : @"Host not found"} ];
}

+ (NSError *)noIPAddressError {
    return [NSError errorWithDomain:@"smb.error" code:52 userInfo:@{ NSLocalizedDescriptionKey : @"Unable to resolve IP address"} ];
}

+ (NSError *)notConnectedError {
    return [NSError errorWithDomain:@"smb.error" code:53 userInfo:@{ NSLocalizedDescriptionKey : @"Not connected"} ];
}

+ (NSError *)notOpenError {
    return [NSError errorWithDomain:@"smb.error" code:54 userInfo:@{ NSLocalizedDescriptionKey : @"Not open"} ];
}

+ (NSError *)writeError {
    return [NSError errorWithDomain:@"smb.error" code:55 userInfo:@{ NSLocalizedDescriptionKey : @"Unable to write to file"} ];
}

+ (NSError *)readError {
    return [NSError errorWithDomain:@"smb.error" code:56 userInfo:@{ NSLocalizedDescriptionKey : @"Unable to read from file"} ];
}

+ (NSError *)dsmError:(int)dsmError session:(smb_session *)session {
    NSString *domain = @"dsm.error";
    NSError *error = nil;
    
    switch (dsmError) {
        case DSM_SUCCESS:
            break;
        case DSM_ERROR_GENERIC:
            error = [NSError errorWithDomain:domain code:1 userInfo:@{ NSLocalizedDescriptionKey : @"Generic error"} ];
            break;
        case DSM_ERROR_NETWORK:
            error = [NSError errorWithDomain:domain code:2 userInfo:@{ NSLocalizedDescriptionKey : @"Network error"} ];
            break;
        case DSM_ERROR_NT:
            error = [self _ntError:smb_session_get_nt_status(session)];
            error = [NSError errorWithDomain:domain code:3 userInfo:@{ NSLocalizedDescriptionKey : @"SMB error", NSUnderlyingErrorKey : error } ];
            break;
        case DSM_ERROR_CHARSET:
            error = [NSError errorWithDomain:domain code:4 userInfo:@{ NSLocalizedDescriptionKey : @"Encoding error"} ];
            break;
        default:
            error = [self unknownError];
            break;
    }
    
    return error;
}

+ (NSError *)_ntError:(uint32_t)nt_status {
    NSString *domain = @"nt.error";
    NSError *error = nil;
    
    switch (nt_status) {
        case NT_STATUS_SUCCESS:
            error = [NSError errorWithDomain:domain code:10 userInfo:@{ NSLocalizedDescriptionKey : @"Success"} ];
            break;
        case NT_STATUS_INVALID_SMB:
            error = [NSError errorWithDomain:domain code:11 userInfo:@{ NSLocalizedDescriptionKey : @"Invalid SMB"} ];
            break;
        case NT_STATUS_SMB_BAD_TID:
            error = [NSError errorWithDomain:domain code:12 userInfo:@{ NSLocalizedDescriptionKey : @"Bad TID"} ];
            break;
        case NT_STATUS_SMB_BAD_UID:
            error = [NSError errorWithDomain:domain code:13 userInfo:@{ NSLocalizedDescriptionKey : @"Bad UID"} ];
            break;
        case NT_STATUS_NOT_IMPLEMENTED:
            error = [NSError errorWithDomain:domain code:14 userInfo:@{ NSLocalizedDescriptionKey : @"Not implemented"} ];
            break;
        case NT_STATUS_INVALID_DEVICE_REQUEST:
            error = [NSError errorWithDomain:domain code:15 userInfo:@{ NSLocalizedDescriptionKey : @"Invalid device request"} ];
            break;
        case NT_STATUS_NO_SUCH_DEVICE:
            error = [NSError errorWithDomain:domain code:16 userInfo:@{ NSLocalizedDescriptionKey : @"No such device"} ];
            break;
        case NT_STATUS_NO_SUCH_FILE:
            error = [NSError errorWithDomain:domain code:17 userInfo:@{ NSLocalizedDescriptionKey : @"No such file"} ];
            break;
        case NT_STATUS_MORE_PROCESSING_REQUIRED:
            error = [NSError errorWithDomain:domain code:18 userInfo:@{ NSLocalizedDescriptionKey : @"More processing required"} ];
            break;
        case NT_STATUS_INVALID_LOCK_SEQUENCE:
            error = [NSError errorWithDomain:domain code:19 userInfo:@{ NSLocalizedDescriptionKey : @"Invalid lock sequence"} ];
            break;
        case NT_STATUS_INVALID_VIEW_SIZE:
            error = [NSError errorWithDomain:domain code:20 userInfo:@{ NSLocalizedDescriptionKey : @"Invalid view size"} ];
            break;
        case NT_STATUS_ALREADY_COMMITTED:
            error = [NSError errorWithDomain:domain code:21 userInfo:@{ NSLocalizedDescriptionKey : @"Already committed"} ];
            break;
        case NT_STATUS_ACCESS_DENIED:
            error = [NSError errorWithDomain:domain code:22 userInfo:@{ NSLocalizedDescriptionKey : @"Access denied"} ];
            break;
        case NT_STATUS_OBJECT_NAME_NOT_FOUND:
            error = [NSError errorWithDomain:domain code:23 userInfo:@{ NSLocalizedDescriptionKey : @"Object name not found"} ];
            break;
        case NT_STATUS_OBJECT_NAME_COLLISION:
            error = [NSError errorWithDomain:domain code:24 userInfo:@{ NSLocalizedDescriptionKey : @"Object name collision"} ];
            break;
        case NT_STATUS_OBJECT_PATH_INVALID:
            error = [NSError errorWithDomain:domain code:25 userInfo:@{ NSLocalizedDescriptionKey : @"Object path invalid"} ];
            break;
        case NT_STATUS_OBJECT_PATH_NOT_FOUND:
            error = [NSError errorWithDomain:domain code:26 userInfo:@{ NSLocalizedDescriptionKey : @"Object path not found"} ];
            break;
        case NT_STATUS_OBJECT_PATH_SYNTAX_BAD:
            error = [NSError errorWithDomain:domain code:27 userInfo:@{ NSLocalizedDescriptionKey : @"Object path syntax bad"} ];
            break;
        case NT_STATUS_PORT_CONNECTION_REFUSED:
            error = [NSError errorWithDomain:domain code:28 userInfo:@{ NSLocalizedDescriptionKey : @"Port connection refused"} ];
            break;
        case NT_STATUS_THREAD_IS_TERMINATING:
            error = [NSError errorWithDomain:domain code:29 userInfo:@{ NSLocalizedDescriptionKey : @"Thread is terminating"} ];
            break;
        case NT_STATUS_DELETE_PENDING:
            error = [NSError errorWithDomain:domain code:30 userInfo:@{ NSLocalizedDescriptionKey : @"Delete pending"} ];
            break;
        case NT_STATUS_PRIVILEGE_NOT_HELD:
            error = [NSError errorWithDomain:domain code:31 userInfo:@{ NSLocalizedDescriptionKey : @"Privilege not held"} ];
            break;
        case NT_STATUS_LOGON_FAILURE:
            error = [NSError errorWithDomain:domain code:32 userInfo:@{ NSLocalizedDescriptionKey : @"Logon failure"} ];
            break;
        case NT_STATUS_DFS_EXIT_PATH_FOUND:
            error = [NSError errorWithDomain:domain code:33 userInfo:@{ NSLocalizedDescriptionKey : @"DFS exit path found"} ];
            break;
        case NT_STATUS_MEDIA_WRITE_PROTECTED:
            error = [NSError errorWithDomain:domain code:34 userInfo:@{ NSLocalizedDescriptionKey : @"Media write protected"} ];
            break;
        case NT_STATUS_ILLEGAL_FUNCTION:
            error = [NSError errorWithDomain:domain code:35 userInfo:@{ NSLocalizedDescriptionKey : @"Illegal function"} ];
            break;
        case NT_STATUS_FILE_IS_A_DIRECTORY:
            error = [NSError errorWithDomain:domain code:36 userInfo:@{ NSLocalizedDescriptionKey : @"File is a directory"} ];
            break;
        case NT_STATUS_FILE_RENAMED:
            error = [NSError errorWithDomain:domain code:37 userInfo:@{ NSLocalizedDescriptionKey : @"File renamed"} ];
            break;
        case NT_STATUS_REDIRECTOR_NOT_STARTED:
            error = [NSError errorWithDomain:domain code:38 userInfo:@{ NSLocalizedDescriptionKey : @"Redirector not started"} ];
            break;
        case NT_STATUS_DIRECTORY_NOT_EMPTY:
            error = [NSError errorWithDomain:domain code:39 userInfo:@{ NSLocalizedDescriptionKey : @"Directory not empty"} ];
            break;
        case NT_STATUS_PROCESS_IS_TERMINATING:
            error = [NSError errorWithDomain:domain code:40 userInfo:@{ NSLocalizedDescriptionKey : @"Process is terminating"} ];
            break;
        case NT_STATUS_TOO_MANY_OPENED_FILES:
            error = [NSError errorWithDomain:domain code:41 userInfo:@{ NSLocalizedDescriptionKey : @"Too many opened files"} ];
            break;
        case NT_STATUS_CANNOT_DELETE:
            error = [NSError errorWithDomain:domain code:42 userInfo:@{ NSLocalizedDescriptionKey : @"Can not delete"} ];
            break;
        case NT_STATUS_FILE_DELETED:
            error = [NSError errorWithDomain:domain code:43 userInfo:@{ NSLocalizedDescriptionKey : @"File deleted"} ];
            break;
        case NT_STATUS_INSUFF_SERVER_RESOURCES:
            error = [NSError errorWithDomain:domain code:44 userInfo:@{ NSLocalizedDescriptionKey : @"Insufficient server resources"} ];
            break;
        case 0xC000A000:
            error = [NSError errorWithDomain:domain code:45 userInfo:@{ NSLocalizedDescriptionKey : @"Cryptographic signature invalid"} ];
            break;
        case 0xC00000CC:
            error = [NSError errorWithDomain:domain code:46 userInfo:@{ NSLocalizedDescriptionKey : @"Share name invalid"} ];
            break;
        default:
            error = [NSError errorWithDomain:domain code:100 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@: %x", @"Unknown NT status", nt_status] } ];
            break;
    }
    
    return error;
}

@end
