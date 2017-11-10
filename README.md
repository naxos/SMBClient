# SMBClient
`SMBClient` is a small dynamic library that allows iOS apps to access SMB/CIFS file servers. `SMBClient` is written in Objective C. The library supports the discovery of SMB devices and shares, listing and managing directories, reading meta data as well as reading and writing files. All functions are implemented in an asynchronous manner, to allow for a fluid user interface.

## Features
* Discover SMB devices on your network
* List file shares
* List/create/delete directories
* Read file meta data
* Read/write/delete files
* Seek/read partial

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

Be it through discovery or direct instantiation, once you have a file server instance, you might want to login:

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

Don't forget to `disconnect:` from the server when you are finished.

### Shares

List the shares on a file server:

```objectivec
[fileServer listShares:^(NSArray<SMBShare *> *shares, NSError *error) {
	if (error) {
		NSLog(@"Unable to list the shares: %@", error);
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
		NSLog(@"Unable to find the share: %@", error);
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

### Listing files

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

All properties (including `isDirectory` and `exists`) of the `SMBFile` class apart from `path` (and `name`, which is part of `path`) are considered meta data. Meta data of a file or directory are implicitly read, when a file was listed (when it was in the result of `listFiles` or `findFile`), opened (`open`) or closed (`close`), or if it has beed created (using `createDirectory` or `createDirectories`). Meta data are not live data and they are not updated automatically. You can check if the meta data was already read for an instance of `SMBFile` with the `hasStatus` property. The property `statusTime` returns the date the meta data was last read (or nil if it was never read). 

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

### Deleting files and directories

You can delete files and directories if you have the permission. Directories need to be empty before they can be deleted.

```objectivec
[file delete:^(NSError *error) {
	if (error) {
		NSLog(@"Unable to delete file: %@", error);
	} else {
		NSLog(@"File deleted");
	}
}];
```

### Creating directories

This is how you create the directory c as a subdirectory of b:

```objectivec
SMBFile *file = [SMBFile fileWithPath:@"/a/b/c" share:share];

[file createDirectory:^(NSError *error) {
	if (error) {
		NSLog(@"Unable to create the directory: %@", error);
	} else {
		NSLog(@"Directory created");
	}
}];
```

The code above will create directory c only, if directory b (and a) already exists. If you want intermediate directories to be created automatically use `createDirectories:`:

```objectivec
SMBFile *file = [SMBFile fileWithPath:@"/a/b/c" share:share];

[file createDirectories:^(NSError *error) {
	if (error) {
		NSLog(@"Unable to create the directory: %@", error);
	} else {
		NSLog(@"Directory created");
	}
}];
```

### Opening files

You need to open a file before you can read from or write to it:

```objectivec
[file open:SMBFileModeRead completion:^(NSError *error) {
	if (error) {
		NSLog(@"Unable to open the file: %@", error);
	} else {
		NSLog(@"File opened: %@", file.name);
	}
}]; 
```

Use `SMBFileModeRead` if you only want to read from a file. Use `SMBFileModeReadWrite` if you want to write to a file (even if you think that you might not require to read it). If you open a file in order to write to it, it will be created if it doesn't exist.

Don't forget to `close:` the file once you're done with it.

### Reading files

Here is how you read (download) a file. Obviously, in a real-life situation you probably wouldn't collect all data in memory. Note, how you are informed about the progress, which makes it easy to e.g. update a progress bar in the user interface. The progress handler may return NO to indicate that the read process should be stopped. Since the progress handler is called asynchronously, this might however not happen instantaneously.

```objectivec
NSUInteger bufferSize = 12000;
NSMutableData *result = [NSMutableData new];

[file read:bufferSize 
  progress:^BOOL(unsigned long long bytesReadTotal, NSData *data, BOOL complete, NSError *error) {

	if (error) {
		NSLog(@"Unable to read from the file: %@", error);
	} else {	
		NSLog(@"Read %ld bytes, in total %llu bytes (%0.2f %%)", 
		      data.length, bytesReadTotal, (double)bytesReadTotal / file.size * 100);
	
		if (data) {
			[result appendData:data];
		}
	}	
	
	if (complete) {
		[file close:^(NSError *error) {
			NSLog(@"Finished reading file");
		}];
	}
	
	return YES;		
}];
```

Note that there is also a variant of the `read` method where you can specify the maximum number of bytes to read, which is useful if you only want to read a portion of the file. This method will probably be used in combination with the `seek` method of `SMBFile`.

### Writing files

Writing (uploading) a file is equally simple:

```objectivec
NSUInteger bufferSize = 12000;
NSData *data = [@"Hello world!\n" dataUsingEncoding:NSUTF8StringEncoding];

[file write:^NSData *(unsigned long long offset) {
	if (offset < data.length) {
		return [data subdataWithRange:NSMakeRange(offset, MIN(bufferSize, data.length - offset))];
	} else {
		return nil;
	}
} progress:^(unsigned long long bytesWrittenTotal, long bytesWrittenLast, BOOL complete, NSError *error) {
	if (error) {
		NSLog(@"Unable to write to the file: %@", error);
	} else {	
    	NSLog(@"Wrote %ld bytes, in total %llu bytes (%0.2f %%)",
		      bytesWrittenLast, bytesWrittenTotal, (double)bytesWrittenTotal / data.length * 100);
    }
	
	if (complete) {
		[file close:^(NSError *error) {
			NSLog(@"Finished writing file");
		}];
	}
}];
```

If you want to append data to an existing file, or if you want to write at a particular position, you can use the `seek` method of `SMBFile` to position the file pointer.

## Dependencies

`SMBClient` relies on [libdsm](http://videolabs.github.io/libdsm), a low level SMB client library written in C, and [libtasn1](https://www.gnu.org/software/libtasn1/), an implementation of the Abstract Syntax Notification ASN.1. Binaries and headers of both libraries are embedded in this library to eliminate external dependencies. The version of `SMBClient` is (currently) tied to the version of `libdsm` included in this library. 

## License

`SMBClient` as well as `libdsm` and `libtasn1` are licensed under the [GNU Lesser General Public License version 2.1](https://www.gnu.org/licenses/lgpl-2.1.html) or later. See the [LICENSE file](LICENSE.md). A commercial license option is available for `libdsm`. [Contact](mailto:info@naxos-software.de) us if you require a license of `SMBClient` to be used with the commercial license of `libdsm`.

