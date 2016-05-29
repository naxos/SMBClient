# SMBClient
`SMBClient` is a small dynamic library that allows iOS apps to access SMB/CIFS file servers. The library supports the discovery of SMB devices and shares, listing and managing directories, reading meta data as well as reading and writing files. All functions are provided in an asynchronous manner, to allow for a fluid user interface.

`SMBClient` is built on top of [libdsm](http://videolabs.github.io/libdsm), a low level SMB client library written in C. A copy of libdsm is embedded in this library to eliminate external dependencies.

##Features
* Discover SMB devices on your network
* List file shares
* List/create/delete directories
* Read file meta data
* Create/read/write files
