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

@implementation SMBDevice

- (instancetype)initWithType:(SMBDeviceType)type host:(NSString *)ipAddressOrHostname netbiosName:(NSString *)name group:(NSString *)group {
    self = [super init];
    if (self) {
        _type = type;
        _host = ipAddressOrHostname;
        _netbiosName = name;
        _group = group;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@(%@)/%@", [self _typeName], _netbiosName, _host, _group];
}

#pragma mark - Private methods

- (NSString *)_typeName {
    switch (_type) {
        case SMBDeviceTypeWorkstation:
            return @"workstation";
        case SMBDeviceTypeMessenger:
            return @"messenger";
        case SMBDeviceTypeDomainMaster:
            return @"domain master";
        case SMBDeviceTypeFileServer:
            return @"file server";
        case SMBDeviceTypeUnknown:
        default:
            return @"unknown device";
    }
}

@end
