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

Start the discovery of SMB devices on your network:

```objectivec
[[SMBDiscovery sharedInstance] startDiscoveryOfType:SMBDeviceTypeAny added:^(SMBDevice *device) {
    NSLog(@"Device added: %@", device);
} removed:^(SMBDevice *device) {
    NSLog(@"Device removed: %@", device);
}];
```

You can also limit the search to file servers:

```objectivec
[[SMBDiscovery sharedInstance] startDiscoveryOfType:SMBDeviceTypeFileServer added:^(SMBDevice *device) {
	SMBFileServer *fileServer = (SMBFileServer *)device;
	
    NSLog(@"File server added: %@", fileServer);
} removed:nil];
```

If however you don't need discovery, you can also instantiate a file server directly:

```objectivec
NSString *host = @"localhost";

SMBFileServer *fileServer = [[SMBFileServer alloc] initWithHost:host netbiosName:host group:nil];
```

### Login

Be it through discovery or direct instantiation, once you have a file server, you might want to login:

```objectivec
[fileServer connectAsUser:@"john" password:@"secret" completion:^(BOOL guest, NSError *error) {
	if (error) {
		NSLog(@"Unable to connect: %@", error);
	} else if (guest) {
		NSLog(@"Logged in as guest");
	} else {
		NSLog(@"Logged in");
	}
}];
```

### Shares

List the shares on a file server:

```objectivec
[fileServer listShares:^(NSArray<SMBShare *> *shares, NSError *error) {
	if (error) {
		NSLog(@"Unable to connect: %@", error);
	} else {
		for (SMBShare *share in shares) {
			NSLog(@"Got share: %@", share.name);
		}
	}
}];
```

Or, if you already know the name of a share you want to use:

```objectivec
[fileServer findShare:@"Guest Share" completion:^(SMBShare *share, NSError * error) {
	if (error) {
		NSLog(@"Unable to find share: %@", error);
	} else {
		NSLog(@"Got share: %@", share.name);
	}
}];
```

You need to open a share to work on it:

```objectivec
[share open:^(NSError * _Nullable error) {
	if (error) {
		NSLog(@"Unable to open share: %@", error);
	} else {
		NSLog(@"Opened share '%@'", share.name);
	}
}];
```



    
