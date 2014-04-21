
#import <HTTPServerKit/HTTPServerKit.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/sysctl.h>

// constants
NSString* const PGHTTPServerErrorDomain = @"PGHTTPServerErrorDomain";
NSString* const PGHTTPServerExecutable = @"sthttpd-current-mac_x86_64/sbin/thttpd";

@implementation PGHTTPServer

////////////////////////////////////////////////////////////////////////////////
#pragma mark CONSTRUCTOR

-(id)init {
	self = [super init];
	if(self) {
		_bonjour = nil;
		_port = 0;
		_task = nil;
		[self setBonjourName:[[NSProcessInfo processInfo] hostName]];
		[self setBonjourType:@"_http._tcp."];
	}
	return self;
}

+(PGHTTPServer* )server {
	return [[PGHTTPServer alloc] init];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PROPERTIES

@synthesize bonjourName, bonjourType;
@dynamic pid,port;

-(NSUInteger)port {
	return _port;
}

-(int)pid {
	return [_task processIdentifier];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PRIVATE METHODS

+(NSBundle* )_bundle {
	return [NSBundle bundleForClass:[self class]];
}

+(NSURL* )_URLForResource:(NSString* )resource {
	NSString* resourceName = [resource stringByDeletingPathExtension];
	NSString* resourceType = [resource pathExtension];
	return [[self _bundle] URLForResource:resourceName withExtension:resourceType];
}

+(NSURL* )serverExecutable {
	return [self _URLForResource:PGHTTPServerExecutable];
}

+(int)_getUnusedPortWithError_impl:(NSError** )error {
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

+(int)_getUnusedPortWithError:(NSError** )error {
	int unusedPort = 0;
	NSUInteger attempts = 0;
	int portMin = 1025;
	do {
		unusedPort = [self _getUnusedPortWithError_impl:error];
	} while(unusedPort < portMin && (attempts++) < 10); // skip root-only ports
	if(unusedPort < portMin) {
		(*error) = [NSError errorWithDomain:PGHTTPServerErrorDomain code:PGHTTPServerErrorUnknown userInfo:nil];
		return 0;
	}
	return unusedPort;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Logging

-(void)_removeNotification {
	NSNotificationCenter* theNotificationCenter = [NSNotificationCenter defaultCenter];
	[theNotificationCenter removeObserver:self];
}

-(void)_addNotificationForFileHandle:(NSFileHandle* )theFileHandle {
	NSNotificationCenter* theNotificationCenter = [NSNotificationCenter defaultCenter];
    [theNotificationCenter addObserver:self
							  selector:@selector(_getTaskData:)
								  name:NSFileHandleReadCompletionNotification
								object:nil];
	[theFileHandle readInBackgroundAndNotify];
}

-(void)_delegateMessageFromData:(NSData* )theData {
	NSString* theMessage = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
	NSArray* theArray = [theMessage componentsSeparatedByString:@"\n"];
	NSEnumerator* theEnumerator = [theArray objectEnumerator];
	NSString* theLine = nil;
	while(theLine = [theEnumerator nextObject]) {
		theLine = [theLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if([theLine length] && [[self delegate] respondsToSelector:@selector(server:log:)]) {
			PGHTTPServerLog* log = [[PGHTTPServerLog alloc] initWithLine:theLine];
			[[self delegate] server:self log:log];
		}
	}
}

-(void)_getTaskData:(NSNotification* )theNotification {
	NSData* theData = [[theNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	[self _delegateMessageFromData:theData];
	if([theData length]) {
		// get more data
		[[theNotification object] readInBackgroundAndNotify];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Server starting

-(void)_backgroundTaskThread:(NSTask* )task {
	@autoreleasepool {
		[task launch];
	}
}

-(NSTask* )_startTask:(NSString* )theBinary arguments:(NSArray* )theArguments {
	NSParameterAssert(theBinary && [theBinary isKindOfClass:[NSString class]]);
	NSParameterAssert(theArguments && [theArguments isKindOfClass:[NSArray class]]);
	NSTask* task = [[NSTask alloc] init];
	NSPipe* thePipe = [[NSPipe alloc] init];

	[task setLaunchPath:theBinary];
	[task setArguments:theArguments];
	[task setStandardOutput:thePipe];
	[task setStandardError:thePipe];

	// add a notification for the pipe's standard out and error
	[self _removeNotification];
	[self _addNotificationForFileHandle:[thePipe fileHandleForReading]];

	// start task in background
	[NSThread detachNewThreadSelector:@selector(_backgroundTaskThread:) toTarget:self withObject:task];

	// wait for task to be running
	while(![task processIdentifier]) {
		[NSThread sleepForTimeInterval:0.01];
	}

	// delegate
	if([[self delegate] respondsToSelector:@selector(server:startedWithURL:)]) {
		NSURL* url = nil;
		[[self delegate] server:self startedWithURL:url];
	}

#ifdef DEBUG
	NSLog(@"Task PID: %d",[task processIdentifier]);
#endif
	
	// return the task
	return task;
}

-(BOOL)_startServerWithDocumentRoot:(NSString* )documentRoot port:(int)port checkSymlinks:(BOOL)isCheckSymlinks {
	NSParameterAssert(documentRoot);
	NSParameterAssert(port > 0);
	
	NSString* binary = [[[self class] serverExecutable] path];
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObjectsFromArray:@[ @"-p",[NSString stringWithFormat:@"%d",port]]];
	[arguments addObjectsFromArray:@[ @"-d",documentRoot]];
	[arguments addObjectsFromArray:@[ @"-l",@"/dev/stdout"]];
	[arguments addObjectsFromArray:@[ @"-D"]];
	if(isCheckSymlinks==NO) {
		[arguments addObjectsFromArray:@[ @"-nos"]];
	}

	if(_task != nil) {
		return NO;
	}
	_port = port;
	_task = [self _startTask:binary arguments:arguments];
	NSParameterAssert(_task);
	_bonjour = [[NSNetService alloc] initWithDomain:@"local." type:[self bonjourType] name:[self bonjourName] port:port];
	NSParameterAssert(_bonjour);
	[_bonjour setDelegate:self];
	[_bonjour publish];
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PUBLIC METHODS

-(BOOL)startWithDocumentRoot:(NSString* )documentRoot port:(int)port {
	NSParameterAssert(documentRoot);
	NSParameterAssert(port >= 0);
	// check document root is readable
	BOOL isPath;
	if([[NSFileManager defaultManager] fileExistsAtPath:documentRoot isDirectory:&isPath]==NO || isPath==NO) {
		return NO;
	}
	// determine port to be used
	NSError* error = nil;
	if(port == 0) {
		port = [[self class] _getUnusedPortWithError:&error];
		if(port==0) {
#ifdef DEBUG
			NSLog(@"Error: %@",error);
#endif
			// couldn't find a standard port
			return NO;
		}
	}
	return [self _startServerWithDocumentRoot:documentRoot port:port checkSymlinks:NO];
}

-(BOOL)startWithDocumentRoot:(NSString* )documentRoot {
	return [self startWithDocumentRoot:documentRoot port:0];
}

-(BOOL)stop {
	if(_task) {
		[_task terminate];
	}
	if(_bonjour) {
		[_bonjour stop];
	}
	_task = nil;
	_bonjour = nil;
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSNetServiceDelegate

-(void)netServiceDidPublish:(NSNetService* )sender {
#ifdef DEBUG
    NSLog(@"NSNetServiceDelegate: netServiceDidPublish: %@",sender);
#endif
}

-(void)netService:(NSNetService* )service didNotPublish:(NSDictionary* )dict {
#ifdef DEBUG
    NSLog(@"NSNetServiceDelegate: Failed to publish: %@",dict);
#endif
}

-(void)netServiceDidStop:(NSNetService* )sender {
#ifdef DEBUG
    NSLog(@"NSNetServiceDelegate: Stopped: %@",sender);
#endif
}


/*

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

*/



@end
