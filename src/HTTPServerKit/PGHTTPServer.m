
#import <HTTPServerKit/HTTPServerKit.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/sysctl.h>

// constants
NSString* const PGHTTPServerErrorDomain = @"PGHTTPServerErrorDomain";
NSString* const PGHTTPServerExecutable = @"sthttpd-current-mac_x86_64/sbin/thttpd";
NSString* const PGHTTPFilePID = @"httpd.pid";

@implementation PGHTTPServer

////////////////////////////////////////////////////////////////////////////////
#pragma mark CONSTRUCTOR

-(id)init {
	return nil;
}

-(id)initWithDataPath:(NSString* )path {
	self = [super init];
	if(self) {
		_state = PGHTTPServerStateUnknown;
		_path = path;
		_bonjour = nil;
		_pid = 0;
		_port = 0;
		[self setBonjourName:[[NSProcessInfo processInfo] hostName]];
		[self setBonjourType:@"_http._tcp."];
	}
	return self;
}

+(PGHTTPServer* )serverWithDataPath:(NSString* )thePath {
	NSParameterAssert(thePath);
	// check for directory and writable
	BOOL isDir = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDir]==NO || isDir==NO) {
		return nil;
	}
	if([[NSFileManager defaultManager] isWritableFileAtPath:thePath]==NO) {
		return nil;
	}
	PGHTTPServer* server = [[PGHTTPServer alloc] initWithDataPath:thePath];
	/*
	NSUInteger pid = [server _pidFromPath:thePath];
	if(pid > 0) {
		[server _setPid:pid];
	}*/
	return server;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PROPERTIES

@synthesize port = _port;
@synthesize pid = _pid;
@synthesize bonjourName, bonjourType;

////////////////////////////////////////////////////////////////////////////////
#pragma mark PRIVATE METHODS

-(NSBundle* )_bundle {
	return [NSBundle bundleForClass:[self class]];
}

-(NSURL* )_URLForResource:(NSString* )resource {
	NSString* resourceName = [resource stringByDeletingPathExtension];
	NSString* resourceType = [resource pathExtension];
	return [[self _bundle] URLForResource:resourceName withExtension:resourceType];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PUBLIC METHODS

-(BOOL)startWithDocumentRoot:(NSString* )documentRoot {
	return NO;
}

-(BOOL)stop {
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNetServiceDelegate

-(void)netService:(NSNetService* )service didNotPublish:(NSDictionary* )dict {
#ifdef DEBUG
    NSLog(@"NSNetServiceDelegate: Failed to publish: %@",dict);
#endif
}


/*


@interface PGHTTPServer (Private)
-(NSUInteger)_pidFromPath:(NSString* )thePath;
-(void)_setPid:(NSUInteger)pid;
@end

-(NSURL* )URL {
	NSString* url = [NSString stringWithFormat:@"http://%@:%d/",[[NSProcessInfo processInfo] hostName],[self  port]];
	return [NSURL URLWithString:url];
}


-(int)_portFromPid:(NSUInteger)pid {
	NSString* portDirective = @"Listen ";
	NSString* confPath = [_path stringByAppendingPathComponent:PGHTTPFileConf];
	NSString* confString = [NSString stringWithContentsOfFile:confPath encoding:NSUTF8StringEncoding error:nil];
	if(confString==nil) {
		return -1;
	}
	int port = 0;
	for(NSString* line in [confString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
		if([line hasPrefix:portDirective]) {
			NSString* portString = [line stringByReplacingOccurrencesOfString:portDirective withString:@""];
			port = [portString intValue];
		}
	}
	return port;
}

-(void)_setPid:(NSUInteger)pid {
	if(pid==0) {
		_state = PGHTTPServerStateStopped;
		_pid = 0;
		_port = 0;
		[_bonjour stop];
		_bonjour = nil;
	} else {
		_state = PGHTTPServerStateStarted;
		_pid = pid;
		_port = [self _portFromPid:pid];
		_bonjour = [[NSNetService alloc] initWithDomain:@"local." type:[self bonjourType] name:[self bonjourName] port:_port];
		NSParameterAssert(_bonjour);
		[_bonjour setDelegate:self];
		[_bonjour publish];
	}
}

-(NSUInteger)_pidFromPath:(NSString* )thePath {
	NSString* thePidPath = [thePath stringByAppendingPathComponent:PGHTTPFilePID];
	if([[NSFileManager defaultManager] fileExistsAtPath:thePidPath]==NO || [[NSFileManager defaultManager] isReadableFileAtPath:thePidPath]==NO) {
		return 0;
	}
	NSDictionary* theAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:thePidPath error:nil];
	if(theAttributes==nil || [theAttributes fileSize] > 1024) {
		return 0;
	}
	NSString* thePidString = [NSString stringWithContentsOfFile:thePidPath encoding:NSUTF8StringEncoding error:nil];
	if(thePidString==nil) {
		return 0;
	}
	// return the PID as a decimal number
	NSDecimalNumber* thePid = [NSDecimalNumber decimalNumberWithString:thePidString];
	if(thePid==nil) {
		return 0;
	}
	// success - return decimal number
	return [thePid unsignedIntegerValue];
}

-(int)_startTask:(NSString* )theBinary arguments:(NSArray* )theArguments {
	NSParameterAssert(theBinary && [theBinary isKindOfClass:[NSString class]]);
	NSParameterAssert(theArguments && [theArguments isKindOfClass:[NSArray class]]);
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:theBinary];
	[theTask setArguments:theArguments];
	[theTask launch];
	[theTask waitUntilExit];
	return [theTask terminationStatus];
}

-(BOOL)_startTaskServerWithConfiguration:(NSString* )confFilePath {
	// set arguments
	NSArray* arguments = @[ @"-f",confFilePath ];
#ifdef DEBUG
	NSLog(@"Starting server with args: %@",[arguments componentsJoinedByString:@" "]);
#endif
	int returnCode = [self _startTask:PGHTTPServerExecutable arguments:arguments];
	if(returnCode != 0) {
		return NO;
	}
	NSUInteger pid = [self _pidFromPath:_path];
	if(pid==0) {
		return NO;
	}
	// set the PID and server state
	[self _setPid:pid];
	// return success
	return YES;
}

-(NSUInteger)_getUnusedPortWithError:(NSError** )error {
	int sfd = socket(AF_INET,SOCK_STREAM,0);
	if(sfd < 0) {
		(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorNetwork userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(errno)] }];
		return 0;
	}
	struct sockaddr_in addr;
	bzero(&addr,sizeof(struct sockaddr_in));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = INADDR_ANY;
	if(bind(sfd,(const struct sockaddr* )&addr,sizeof(struct sockaddr_in)) < 0) {
		(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorNetwork userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(errno)] }];
		close(sfd);
		return 0;
	}
	socklen_t length;
	if(getsockname(sfd,(struct sockaddr* )&addr,&length) < 0) {
		(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorNetwork userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(errno)] }];
		close(sfd);
		return 0;
	}
	close(sfd);
	return addr.sin_port;
}

-(NSUInteger)getUnusedPortWithError:(NSError** )error {
	NSUInteger unusedPort = 0;
	NSUInteger attempts = 0;
	NSUInteger portMin = 1025;
	do {
		unusedPort = [self _getUnusedPortWithError:error];
	} while(unusedPort < portMin && (attempts++) < 10); // skip root-only ports
	if(unusedPort < portMin) {
		(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorUnknown userInfo:nil];
		return 0;
	}
	return unusedPort;
}

-(NSString* )_replaceInTemplate:(NSString* )template dictionary:(NSDictionary* )values error:(NSError** )error {
	NSParameterAssert(template);
	NSParameterAssert(values);
	NSScanner* scanner = [NSScanner scannerWithString:template];
	NSString* tmp = nil;
	NSMutableString* output = [NSMutableString stringWithCapacity:[template length]];
	NSUInteger state = 0;
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	while([scanner isAtEnd]==NO) {
		switch(state) {
			case 0:
				if([scanner scanUpToString:@"{" intoString:&tmp]==YES) {
					state = 1;
				}
				break;
			case 1:
				[scanner scanString:@"{" intoString:nil];
				if([scanner scanUpToString:@"}" intoString:&tmp]==YES) {
					[scanner scanString:@"}" intoString:nil];
					NSString* value = [[values objectForKey:tmp] description];
					if(value==nil) {
						(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorTemplate userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unknown template parameter: %@",value] }];
						return nil;
					} else {
						tmp = value;
					}
					state = 0;
				} else {
					(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorTemplate userInfo:@{ NSLocalizedDescriptionKey:@"Missing closing brace" }];
					return nil;
				}
				break;
		}
		[output appendString:tmp];
	}
	return output;
}

-(BOOL)_removeFileIfExists:(NSString* )path error:(NSError** )error {
	BOOL isDir = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]==NO) {
		return YES;
	}
	if(isDir==YES) {
		(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorUnknown userInfo:nil];
		return NO;
	}
	return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

////////////////////////////////////////////////////////////////////////////////
// determine if process is still running
// see: http://www.cocoadev.com/index.pl?HowToDetermineIfAProcessIsRunning

-(int)_doesProcessExist:(NSUInteger)pid {
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, (int)pid };
	int returnValue = 1;
	size_t count;
	if(sysctl(mib,4,0,&count,0,0) < 0 ) {
		return 0;
	}
	struct kinfo_proc* kp = (struct kinfo_proc* )malloc(count);
	if(kp==nil) return -1;
	if(sysctl(mib,4,kp,&count,0,0) < 0) {
		returnValue = -1;
	} else {
		long nentries = (long)count / (long)sizeof(struct kinfo_proc);
		if(nentries < 1) {
			returnValue = 0;
		}
	}
	free(kp);
	return returnValue;
}

-(void)_stopProcess:(NSUInteger)thePid {
	// set counter and state
	int count = 0;
	// wait until process identifier is minus one
	do {
		if(count==0) {
#ifdef DEBUG
			NSLog(@"killing PID %lu, SIGTERM",thePid);
#endif
			kill((int)thePid,SIGTERM);
		} else if(count==100) {
#ifdef DEBUG
			NSLog(@"killing PID %lu, SIGINT",thePid);
#endif
			kill((int)thePid,SIGINT);
		} else if(count==300) {
#ifdef DEBUG
			NSLog(@"killing PID %lu, SIGKILL",thePid);
#endif
			kill((int)thePid,SIGKILL);
		}
		// sleep for 100ms
		[NSThread sleepForTimeInterval:0.1];
		count++;
	} while([self _doesProcessExist:thePid]);
}

-(BOOL)startWithDocumentRoot:(NSString* )documentRoot {
	NSError* error = nil;
	
	NSUInteger unusedPort = [self port];
	if(unusedPort == 0) {
		unusedPort = [self getUnusedPortWithError:&error];
		if(unusedPort==0) {
#ifdef DEBUG
			NSLog(@"Error1: %@",error);
#endif
			// couldn't find a standard port
			return NO;
		}
	}
	
	// remove existing log and configuration files
	NSString* logPath = [_path stringByAppendingPathComponent:PGHTTPFileLog];
	NSString* confPath = [_path stringByAppendingPathComponent:PGHTTPFileConf];
	if([self _removeFileIfExists:logPath error:&error]==NO) {
#ifdef DEBUG
		NSLog(@"Error2: %@",error);
#endif
		return NO;
	}
	if([self _removeFileIfExists:confPath error:&error]==NO) {
#ifdef DEBUG
		NSLog(@"Error3: %@",error);
#endif
		return NO;
	}
	
	// create configuration file
	NSDictionary* dictionary = @{
		@"PORT": [NSString stringWithFormat:@"%ld",unusedPort],
		@"DOCROOT": documentRoot,
		@"APPROOT": _path,
		@"PIDFILE": PGHTTPFilePID,
		@"LOGFILE": PGHTTPFileLog,
		@"LOCKFILE": PGHTTPFileLock
	};
	NSURL* templateURL = [self URLForResource:PGHTTPFileConf];
	if(templateURL==nil || [[NSFileManager defaultManager] fileExistsAtPath:[templateURL path]]==NO) {
#ifdef DEBUG
		NSLog(@"Error: Missing resource: %@",PGHTTPFileConf);
#endif
		return NO;
	}
	
	NSString* template = [NSString stringWithContentsOfURL:templateURL encoding:NSUTF8StringEncoding error:&error];
	if(template==nil) {
#ifdef DEBUG
		NSLog(@"Error4: %@",error);
#endif
		return NO;
	}
	
	NSString* output = [self _replaceInTemplate:template dictionary:dictionary error:&error];
	if(output==nil) {
#ifdef DEBUG
		NSLog(@"Error5: %@",error);
#endif
		return NO;
	}

	if([output writeToFile:confPath atomically:YES encoding:NSUTF8StringEncoding error:&error]==NO) {
#ifdef DEBUG
		NSLog(@"Error6: %@",error);
#endif
		return NO;
	}
	
	// start the server
	if([self _startTaskServerWithConfiguration:confPath]==NO) {
#ifdef DEBUG
		NSLog(@"Error7: Unable to start the server");
#endif
		return NO;
	}
	
	return YES;
}

-(BOOL)stop {
	BOOL returnValue = NO;
	if(_pid) {
		[self _stopProcess:_pid];
		NSString* confPath = [_path stringByAppendingPathComponent:PGHTTPFileConf];
		[self _removeFileIfExists:confPath error:nil];
		returnValue = YES;
	}
	[self _setPid:0];
	return returnValue;
}

*/



@end
