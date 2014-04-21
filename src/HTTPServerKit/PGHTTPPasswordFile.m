
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

	NSPipe* inPipe = [NSPipe new];
	NSPipe* outPipe = [NSPipe new];
	NSString* password2 = [NSString stringWithFormat:@"%@\n",password];
	NSData* inData = [password2 dataUsingEncoding:NSUTF8StringEncoding];
	
	[task setStandardInput:inPipe];
	[task setStandardOutput:outPipe];
//	[task setStandardError:outPipe];
	[task launch];
	
	[[inPipe fileHandleForWriting] writeData:inData];
	[[inPipe fileHandleForWriting] writeData:inData];
	[[inPipe fileHandleForWriting] closeFile];
	
	[task waitUntilExit];
	
	NSLog(@"termination status %d",[task terminationStatus]);
	
	return YES;
}

@end
