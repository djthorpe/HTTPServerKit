
HTTPServerKit
=============

Embeddable HTTP Server for Mac OS X. Please see LICENSE file for licensing
information regarding the Objective-C framework. Includes code from
http://opensource.dyc.edu/sthttpd - license information for that is included
below.

Introduction
------------

This embeddable HTTP server framework allows you to serve static files within a 
document root path. It spawns a `thttpd` server (http://opensource.dyc.edu/sthttpd) which
is used for doing the serving. You can implement a delegate which can be told
when the server starts, stops or when a request has been made to the server. Features
of the server are:

  * Simple to use
  * Registers your service via Bonjour
  * Can allocate an unused port on startup
  * Provides your application with a history of requests
  * User authentication


Building
--------

To build the framework, you'll need to have a copy of XCode and use the script
`build-release.sh` in the `etc` folder. This will build both a release version
of the framework and a HTTPServer test application in your regular build folder.

Embedding in your application
-----------------------------

You'll need a new copy phase when building your Cocoa-app, so it copies the
`HTTPServerKit` framework over to your Package `Frameworks` folder, and include
the following line in your source code:

```
#import <HTTPServerKit/HTTPServerKit.h>
```

You create a server instance and start serving using the following kind of
code:

```
	PGHTTPServer* server = [PGHTTPServer server];
	int port = ....;
	NSString* docroot = ...;
	[server setDelegate:self];
	BOOL isSuccess;
	if(port) {
		isSuccess = [server startWithDocumentRoot:docroot port:port];
	} else {
		isSuccess = [server startWithDocumentRoot:docroot];
	}
```

If you start the server without a named port, the server will attempt to use
an unused port. You can determine which port has been used with the property
`[server port]` or you can implement the delegate method which is called when
the server is started.

Bonjour
-------

The server always publishes it's location using Bonjour (http://www.apple.com/support/bonjour/).
You can set the `[server bonjourName]` and `[server bonjourType]` properties
of the server to publish the service as a non-HTTP service or with a different name.

Using the delegate
------------------

The delegate protocol is as follows:

```
@protocol PGHTTPServerDelegate <NSObject>
	@optional
		-(void)server:(PGHTTPServer* )server startedWithURL:(NSURL* )url;
		-(void)serverStopped:(PGHTTPServer* )server;
		-(void)server:(PGHTTPServer* )server log:(PGHTTPServerLog* )log;
@end
```

When starting the server, a URL is passed which can be used to access the
server remotely. Whenever a request is served, the `server:log:` message is
sent which gives information on the request. The properties of the `PGHTTPServerLog`
object are as follows:

```
@property (retain) NSString* hostname;
@property (retain) NSString* user;
@property (retain) NSString* group;
@property (retain) NSString* timestamp;
@property (retain) NSString* request;
@property (assign) NSInteger httpcode;
@property (assign) unsigned long long length;
@property (retain) NSString* referer;
@property (retain) NSString* useragent;
```

You can also retrieve a dictionary of the key value pairs by 
calling `[log dictionary]`.

Using Basic Authentication
--------------------------

A global password file (which includes username and password pairs) can be
retrieved using `[server globalPasswordFile]` once the server has been
started. This method returns `nil` if the document root directory is not
writable or if the server has not yet been started. For example,

```
   PGHTTPPasswordFile* passwd = [server globalPasswordFile];
```

A list of users in the file can be retrived using the `[passwd users]`
property. A user can be added or the password changed using the method
`[passwd setPassword:forUser:]`. The password file is automatically saved
whenever a change is made.



sthttpd License
===============

Credits:

  1. The original codebase is by Jef Poskanzer <jef@mail.acme.com>  http://www.acme.com/jef/ Please send all kudos to him.

  2. The fork is by Anthony G. Basile <blueness@gentoo.org> http://opensource.dyc.edu/sthttpd Send all blame to him.  Feel free to open a bug regarding sthttpd at http://opensource.dyc.edu/bugzilla3/

  3. thttpd is released under a BSD license.  Any extended code added by sthttpd is also released under the same license.  Here's a copy of it from the `src/thttpd.c` file:

```
** Copyright 1995,1998,1999,2000,2001 by Jef Poskanzer <jef@mail.acme.com>.
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions
** are met:
** 1. Redistributions of source code must retain the above copyright
**    notice, this list of conditions and the following disclaimer.
** 2. Redistributions in binary form must reproduce the above copyright
**    notice, this list of conditions and the following disclaimer in the
**    documentation and/or other materials provided with the distribution.
**
** THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
** ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
** OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
** HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
** LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
** OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
** SUCH DAMAGE.
```

