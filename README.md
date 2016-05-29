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

When your app goes into the background, or you don't need discovery anymore, make sure to stop it:

```objectivec
[[SMBDiscovery sharedInstance] stopDiscovery];
```

If however you don't need/want discovery at all, you can also instantiate a file server directly:

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
[fileServer findShare:@"Guest Share" completion:^(SMBShare *share, NSError *error) {
	if (error) {
		NSLog(@"Unable to find share: %@", error);
	} else {
		NSLog(@"Got share: %@", share.name);
	}
}];
```

You need to open a share to be able to work on it:

```objectivec
[share open:^(NSError *error) {
	if (error) {
		NSLog(@"Unable to open share: %@", error);
	} else {
		NSLog(@"Opened share '%@'", share.name);
	}
}];
```

Don't forget to `close:` the share, once you're done.

### List files

You have two options to list the files on an open share. Either use `listFiles:` on the share instance:

```objectivec
[share listFiles:^(NSArray<SMBFile *> *files, NSError *error) {
	if (error) {
		NSLog(@"Unable to list files: %@", error);
	} else {
		NSLog(@"Found %lu files", (unsigned long)files.count);
	}
}];
```

Or, you can get the root directory of the share and `listFiles:` there:

```objectivec
SMBFile *root = [SMBFile rootOfShare:share];

[root listFiles:^(NSArray<SMBFile *> *files, NSError *error) {
	if (error) {
		NSLog(@"Unable to list files: %@", error);
	} else {
		NSLog(@"Found %lu files", (unsigned long)files.count);
	}
}];
```

Both methods are equivalent and the choice is just a matter of your personal taste.

You can also filter files when you list them, e.g. to only list directories:

```objectivec
[root listFilesUsingFilter:^BOOL(SMBFile *file) {
	return file.isDirectory;
} completion:^(NSArray<SMBFile *> *files, NSError *error) {
	if (error) {
		NSLog(@"Unable to list files: %@", error);
	} else {
		NSLog(@"Found %lu files", (unsigned long)files.count);
	}
}];
```

This brings us to the meta data of files.

### Meta data

All properties (including `isDirectory` and `exists`) of the `SMBFile` class apart from `path` (and `name`, which is part of `path`) are considered meta data. Meta data are read, when a file is being listed, opened or closed. Meta data are not updated automatically and they are not live data. You can check if the meta data was already read for an instance of `SMBFile` with the `hasStatus` property. The property `statusTime` returns the date the meta data was last read (or nil if it was never read). 

To explicitly read or update a file's meta data use `updateStatus:`:

```objectivec
SMBFile *file = [SMBFile fileWithPath:@"/a/test.txt" share:share];

[file updateStatus:^(NSError *error) {
	if (error) {
		NSLog(@"Unable to read the meta data: %@", error);
	} else {
		if (file.exists) {
			NSLog(@"File %@", file);
		} else {
			NSLog(@"File does not exist");
		}
	}
}];
```

