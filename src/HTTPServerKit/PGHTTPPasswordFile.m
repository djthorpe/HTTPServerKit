
#import "PGHTTPPasswordFile.h"


// constants
NSString* const PGHTTPPasswordFilename = @".htpasswd";
NSString* const PGHTTPPasswdExecutable = @"sthttpd-current-mac_x86_64/sbin/th_htpasswd";

// forward declarations
@interface PGHTTPPasswordFile (Private)
-(NSString* )_fileFromPath:(NSString* )path;
@end

@implementation PGHTTPPasswordFile

////////////////////////////////////////////////////////////////////////////////
#pragma mark CONSTRUCTOR

-(id)init {
	return nil;
}

-(id)initWithPath:(NSString* )path {
	self = [super init];
	if(self) {
		_file = [self _fileFromPath:path];
		if(_file==nil) {
			return nil;
		}
		_read = NO;
	}
	return self;
}

+(PGHTTPPasswordFile* )passwordFileForPath:(NSString* )path {
	return [[PGHTTPPasswordFile alloc] initWithPath:path];
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

+(NSURL* )passwdExecutable {
	return [self _URLForResource:PGHTTPPasswdExecutable];
}

-(NSString* )_fileFromPath:(NSString* )path {
	NSParameterAssert(path);
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]==NO || isDir==NO) {
		return nil;
	}
	return [path stringByAppendingPathComponent:PGHTTPPasswordFilename];
}

-(BOOL)_fileExists {
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:_file isDirectory:&isDir]==NO || isDir==YES) {
		return NO;
	}
	if([[NSFileManager defaultManager] isReadableFileAtPath:_file]==NO) {
		return NO;
	}
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PUBLIC METHODS

-(BOOL)setPassword:(NSString* )password forUser:(NSString* )user {
	NSTask* task = [NSTask new];
	NSURL* binary = [[self class] passwdExecutable];
	NSMutableArray* arguments = [NSMutableArray array];
	if([self _fileExists]==NO) {
		[arguments addObject:@"-c"];
	}
	[arguments addObject:_file];
	[arguments addObject:user];
	[task setLaunchPath:[binary path]];
	[task setArguments:arguments];

	NSFileHandle* input = [NSFileHandle fileHandleWithStandardInput];
	NSPipe* inPipe = [NSPipe new];
	[task setStandardInput:inPipe];
	[input waitForDataInBackgroundAndNotify];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:inPipe queue:nil usingBlock:^(NSNotification *note) {
		NSData* inData = [input availableData];
		if ([inData length] == 0) {
			NSLog(@"EOF on standard input");
			// EOF on standard input.
			[[inPipe fileHandleForWriting] closeFile];
		} else {
			NSLog(@"read from input");
			// Read from standard input and write to shell input pipe.
			[[inPipe fileHandleForWriting] writeData:inData];
			// Continue waiting for standard input.
			[input waitForDataInBackgroundAndNotify];
		}
	}];
	
	[task launch];
	[task waitUntilExit];
	return YES;
}

@end
