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

#import "SMBFileServer_Protected.h"
#import "SMBError.h"
#import "SMBShare_Protected.h"

#import <netdb.h>

#import "smb_session.h"
#import "smb_share.h"

@interface SMBFileServer ()

@property (nonatomic) dispatch_queue_t serialQueue;

@end

@implementation SMBFileServer

- (instancetype)initWithHost:(NSString *)ipAddressOrHostname netbiosName:(NSString *)name group:(NSString *)group {
    self = [super initWithType:SMBDeviceTypeFileServer host:ipAddressOrHostname netbiosName:name group:group];
    if (self) {
        NSString *queueName = [NSString stringWithFormat:@"smb_server_queue_%@", ipAddressOrHostname];

        _serialQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    
    if (_smbSession) {
        smb_session_destroy(_smbSession);
        _smbSession = nil;
    }
}

- (void)connectAsUser:(NSString *)username password:(NSString *)password completion:(void (^)(BOOL, NSError *))completion {
    [self disconnect:^{

        dispatch_async(_serialQueue, ^{
            
            const char *name = self.netbiosName.UTF8String;
            const char *host = self.host.UTF8String;
            const char *user = username.length > 0 ? username.UTF8String : " ";
            const char *pass = password.length > 0 ? password.UTF8String : " ";
            NSError *error = nil;
            BOOL guest = NO;
            const struct hostent *host_entry = gethostbyname(host);
            
            if (host_entry == NULL) {
                error = [SMBError hostNotFoundError];
            } else if (host_entry->h_addr_list[0] == NULL) {
                error = [SMBError noIPAddressError];
            } else {
                
                _smbSession = smb_session_new();
                
                if (_smbSession) {
                    const struct in_addr addr = *(struct in_addr *)host_entry->h_addr_list[0];
                    
                    smb_session_set_creds(_smbSession, name, user, pass);
                    
                    // Connect to the host
                    int result = smb_session_connect(_smbSession, name, addr.s_addr, SMB_TRANSPORT_TCP);
                    
                    if (result == 0) {
                        // Login
                        result = smb_session_login(_smbSession);
                    }
                    
                    if (result == 0) {
                        if (smb_session_is_guest(_smbSession) > 0) {
                            guest = YES;
                        }
                    } else {
                        error = [SMBError dsmError:result session:_smbSession];
                        
                        [self disconnect:nil];
                    }
                } else {
                    error = [SMBError unknownError];
                }
            }
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(guest, error);
                });
            }
        });
    }];
    
}

- (void)disconnect:(nullable void (^)())completion {
    
    dispatch_async(_serialQueue, ^{
        if (_smbSession) {
            smb_session_destroy(_smbSession);
            _smbSession = nil;
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)findShare:(nonnull NSString *)name completion:(nullable void (^)(SMBShare *_Nullable, NSError *_Nullable))completion {
    
    [self listShares:^(NSArray<SMBShare *> *shares, NSError *error) {
        SMBShare *share = nil;
        
        if (error == nil) {
            for (SMBShare *s in shares) {
                if ([s.name isEqualToString:name]) {
                    share = s;
                    break;
                }
            }
        }
        
        if (completion) {
            completion(share, error);
        }
    }];
}

- (void)listShares:(nullable void (^)(NSArray<SMBShare *> *_Nullable, NSError *_Nullable))completion {
    
    dispatch_async(_serialQueue, ^{
        
        NSMutableArray *shares = nil;
        NSError *error = nil;
        smb_share_list list;
        size_t shareCount = 0;
        
        if (self.smbSession) {
            int dsm_error = smb_share_get_list(self.smbSession, &list, &shareCount);
            
            if (dsm_error == 0) {
                
                shares = [NSMutableArray array];
                
                for (NSInteger i = 0; i < shareCount; i++) {
                    const char *cname = smb_share_list_at(list, i);
                    
                    // Exclude system shares suffixed by '$'
                    if (cname[strlen(cname) - 1] != '$') {
                        
                        NSString *shareName = [NSString stringWithUTF8String:cname];
                        
                        SMBShare *share = [[SMBShare alloc] initWithName:shareName server:self];
                        
                        [shares addObject:share];
                    }
                }
                
                smb_share_list_destroy(list);
            } else {
                error = [SMBError dsmError:dsm_error session:self.smbSession];
            }
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(shares, error);
            });
        }
    });
}

- (void)openShare:(nonnull NSString *)name completion:(nullable void (^)(smb_tid, NSError * _Nullable))completion {
    dispatch_async(_serialQueue, ^{
        smb_tid shareID = -1;
        NSError *error = nil;
        
        if (self.smbSession) {
            int dsm_error = smb_tree_connect(self.smbSession, name.UTF8String, &shareID);
            
            if (dsm_error != 0) {
                error = [SMBError dsmError:dsm_error session:self.smbSession];
            }
            
        } else {
            error = [SMBError notConnectedError];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(shareID, error);
            });
        }
    });
}

- (void)closeShare:(smb_tid)shareID completion:(nullable void (^)(NSError * _Nullable))completion {
    dispatch_async(_serialQueue, ^{
        NSError *error = nil;
        
        if (self.smbSession) {
            int dsm_error = smb_tree_disconnect(self.smbSession, shareID);
            
            if (dsm_error != 0) {
                error = [SMBError dsmError:dsm_error session:self.smbSession];
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

@end
