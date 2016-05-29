# SMBClient
`SMBClient` is a small dynamic library that allows iOS apps to access SMB/CIFS file servers. `SMBClient` is written in Objective C. The library supports the discovery of SMB devices and shares, listing and managing directories, reading meta data as well as reading and writing files. All functions are provided in an asynchronous manner, to allow for a fluid user interface.

`SMBClient` is built on top of [libdsm](http://videolabs.github.io/libdsm), a low level SMB client library written in C. A copy of libdsm is embedded in this library to eliminate external dependencies.

## Features
* Discover SMB devices on your network
* List file shares
* List/create/delete directories
* Read file meta data
* Create/read/write files

## Examples

### Discovery

To start the discovery of SMB devices on your network

```Objective C
[[SMBDiscovery sharedInstance] startDiscoveryOfType:SMBDeviceTypeAny added:^(SMBDevice *device) {
    NSLog(@"Device added: %@", device);
} removed:^(SMBDevice *device) {
    NSLog(@"Device removed: %@", device);
}];
```

You can also limit the serch to file servers:

```Objective C
[[SMBDiscovery sharedInstance] startDiscoveryOfType:SMBDeviceTypeFileServer added:^(SMBDevice *device) {
    NSLog(@"File server added: %@", (SMBFileServer *)device);
} removed:nil];
```

