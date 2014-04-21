
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

