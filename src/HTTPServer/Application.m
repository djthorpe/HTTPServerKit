
#import "Application.h"
#import "GBCommandLineParser.h"

NSString* const kHTTPServerErrorDomain = @"HTTPServerError";
NSString* const kHTTPServerIdentifier = @"com.mutablelogic.HTTPServer";

@implementation Application

////////////////////////////////////////////////////////////////////////////////
#pragma mark PROPERTIES

@synthesize error = _error;
@synthesize showHelp = _flag_help;

////////////////////////////////////////////////////////////////////////////////
#pragma mark PRIVATE METHODS

-(BOOL)_parseAppendArgument:(NSString* )argument {
	if(_flag_docroot != nil) {
		return NO;
	}
	BOOL isDir;
	if([[NSFileManager defaultManager] fileExistsAtPath:argument isDirectory:&isDir]==NO || isDir==NO) {
		return NO;
	}
	if([[NSFileManager defaultManager] isReadableFileAtPath:argument]==NO) {
		return NO;
	}
	_flag_docroot = argument;
	return YES;
}

-(BOOL)_parseOptionPort:(NSString* )argument {
	int port = [argument intValue];
	if(port < 1) {
		return NO;
	}
	_flag_port = port;
	return YES;
}

-(NSURL* )_applicationSupportURLWithSubpath:(NSString* )subpath error:(NSError** )error {
	NSURL* applicationSupportURL = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:error] URLByResolvingSymlinksInPath];
	if(applicationSupportURL==nil) {
		return nil;
	}
	applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:kHTTPServerIdentifier isDirectory:YES];
	if(subpath && [subpath length]) {
		applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:subpath isDirectory:YES];
	}
	// create application support directory
	if([[NSFileManager defaultManager] createDirectoryAtURL:applicationSupportURL withIntermediateDirectories:YES attributes:nil error:error]==NO) {
		return nil;
	}
	// return URL
	return applicationSupportURL;
}

-(NSURL* )_applicationSupportURLWithError:(NSError** )error {
	return [self _applicationSupportURLWithSubpath:nil error:error];
}

-(void)log:(NSString* )message {
	fprintf(stderr,"%s\n",[message UTF8String]);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGHTTPServerDelegate

-(void)server:(PGHTTPServer *)server startedWithURL:(NSURL *)url {
	if(_flag_verbose) {
		[self log:[NSString stringWithFormat:@"Server started: %@",url]];
	}
}

-(void)server:(PGHTTPServer *)server log:(PGHTTPServerLog *)log {
	if(_flag_verbose) {
		[self log:[NSString stringWithFormat:@"%@ => %ld",[log request],[log httpcode]]];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PUBLIC METHODS

-(void)setErrorWithCode:(NSInteger)code description:(NSString* )description {
	NSDictionary* userInfo = @{
		NSLocalizedDescriptionKey: description
	};
	[self setError:[NSError errorWithDomain:kHTTPServerErrorDomain code:code userInfo:userInfo]];
}

-(BOOL)parseCommandLineArguments:(const char** )argv count:(int)argc {
	NSParameterAssert(argv);
	NSParameterAssert(argc);
	
	GBCommandLineParser* parser = [[GBCommandLineParser alloc] init];
	[parser registerSwitch:@"verbose" shortcut:'v'];
	[parser registerSwitch:@"help" shortcut:'h'];
	[parser registerOption:@"port" shortcut:'p' requirement:GBValueRequired];
    [parser parseOptionsWithArguments:(char** )argv count:argc block:^(GBParseFlags flags,NSString* option,id value,BOOL* stop) {
        switch (flags) {
		case GBParseFlagUnknownOption:
			[self setErrorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Unknown option: '%@'",option]];
			(*stop) = YES;
			break;
		case GBParseFlagMissingValue:
			[self setErrorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Missing value for option: '%@'",option]];
			(*stop) = YES;
			break;
		case GBParseFlagArgument:
			(*stop) = [self _parseAppendArgument:value] ? NO : YES;
			if((*stop)) {
				[self setErrorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Invalid argument: '%@'",value]];
			}
			break;
		case GBParseFlagOption:
			if([option isEqual:@"help"]) {
				_flag_help = YES;
				(*stop) = YES;
			} else if([option isEqual:@"verbose"]) {
				NSParameterAssert([(NSNumber* )value isKindOfClass:[NSNumber class]]);
				_flag_verbose = [(NSNumber* )value boolValue];
			} else if([option isEqual:@"port"]) {
				NSParameterAssert([(NSString* )value isKindOfClass:[NSString class]]);
				if([self _parseOptionPort:value]==NO) {
					[self setErrorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Missing or invalid value for option: '%@'",option]];
				}
			} else {
				[self setErrorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Unknown option: '%@'",option]];
				(*stop) = YES;
			}
			break;
		}
    }];
	return [self error] ? NO : YES;
}

-(void)run:(id)sender {
	// create server
	NSParameterAssert(_server==nil);
	_server = [PGHTTPServer server];
	NSParameterAssert(_server);
	[_server setDelegate:self];
	if(_flag_docroot==nil) {
		_flag_docroot = NSHomeDirectory();
	}
	if(_flag_port) {
		[_server startWithDocumentRoot:_flag_docroot port:_flag_port];
	} else {
		[_server startWithDocumentRoot:_flag_docroot];
	}
}

-(void)stop:(id)sender {
	[_server stop];
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

@end
