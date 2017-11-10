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

#import "SMBDiscovery.h"
#import "SMBFileServer.h"
#import "netbios_ns.h"
#import "netbios_defs.h"

#import <netdb.h>
#import <arpa/inet.h>

@implementation SMBDiscovery {
    netbios_ns *_nameService;
}

static void (^_addedHandler)(SMBDevice *_Nonnull);
static void (^_removedHandler)(SMBDevice *_Nonnull);
static SMBDeviceType _typeMask;

+ (instancetype)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void)dealloc {
    [self stopDiscovery];
}

- (BOOL)startDiscoveryOfType:(SMBDeviceType)typeMask added:(nullable void (^)(SMBDevice *_Nonnull))added removed:(nullable void (^)(SMBDevice *_Nonnull))removed {
    if (_nameService) {
        [self stopDiscovery];
    }
    
    _nameService = netbios_ns_new();
    _addedHandler = added;
    _removedHandler = removed;
    _typeMask = typeMask;
    
    netbios_ns_discover_callbacks callbacks;
    
    callbacks.p_opaque = (__bridge void *)self;
    callbacks.pf_on_entry_added = _on_entry_added;
    callbacks.pf_on_entry_removed = _on_entry_removed;
    
    return netbios_ns_discover_start(_nameService,
                                     4, // broadcast every 4 sec
                                     &callbacks) == 0;
}

- (void)stopDiscovery {
    if (_nameService) {
        netbios_ns_discover_stop(_nameService);
        netbios_ns_destroy(_nameService);
        _nameService = NULL;
        _addedHandler = NULL;
        _removedHandler = NULL;
    }
}

static SMBDevice *_device(netbios_ns_entry *entry) {
    SMBDevice *device;
    struct in_addr addr;
    
    addr.s_addr = netbios_ns_entry_ip(entry);
    
    const char *i = inet_ntoa(addr);
    const char *g = netbios_ns_entry_group(entry);
    const char *n = netbios_ns_entry_name(entry);
    const char t = netbios_ns_entry_type(entry);

    SMBDeviceType type = SMBDeviceTypeUnknown;
    NSString *ip = i ? [NSString stringWithUTF8String:i] : nil;
    NSString *group = g ? [NSString stringWithUTF8String:g] : nil;
    NSString *name = n ? [NSString stringWithUTF8String:n] : nil;
    
    switch (t) {
        case NETBIOS_FILESERVER:
            device = [[SMBFileServer alloc] initWithHost:ip netbiosName:name group:group];
            break;
        case NETBIOS_WORKSTATION:
        case NETBIOS_MESSENGER:
        case NETBIOS_DOMAINMASTER:
        default:
            device = [[SMBDevice alloc] initWithType:type host:ip netbiosName:name group:group];
            break;
    }
    
    return device;
}

static void _on_entry_added(void *p_opaque, netbios_ns_entry *entry) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_addedHandler) {
            SMBDevice *device = _device(entry);
            
            if (_typeMask & device.type) {
                _addedHandler(_device(entry));
            }
        }
    });
}

static void _on_entry_removed(void *p_opaque, netbios_ns_entry *entry) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_removedHandler) {
            SMBDevice *device = _device(entry);
            
            if (_typeMask & device.type) {
                _removedHandler(_device(entry));
            }
        }
    });
}

@end
