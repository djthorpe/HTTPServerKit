
#import "Application.h"
#import "GBCommandLineParser.h"

NSString* const kHTTPServerErrorDomain = @"HTTPServerError";

@implementation Application

////////////////////////////////////////////////////////////////////////////////
#pragma mark PROPERTIES

@synthesize returnCode;

////////////////////////////////////////////////////////////////////////////////
#pragma mark PRIVATE METHODS

-(NSError* )_errorWithCode:(int)code description:(NSString* )description {
	NSDictionary* userInfo = @{
		NSLocalizedDescriptionKey: description
	};
	NSError* error = [NSError errorWithDomain:kHTTPServerErrorDomain code:code userInfo:userInfo];
	[self setReturnCode:code];
	return error;
}

-(BOOL)_parseAppendArgument:(NSString* )argument error:(NSError** )error {

	return YES;
}

-(BOOL)_parseOptionPort:(NSString* )argument error:(NSError** )error {

	return YES;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark PUBLIC METHODS

-(void)parseCommandLineArguments:(const char** )argv count:(int)argc error:(NSError** )error {
	NSParameterAssert(argv);
	NSParameterAssert(argc);
	NSParameterAssert(error);
	
	GBCommandLineParser* parser = [[GBCommandLineParser alloc] init];
	[parser registerSwitch:@"verbose" shortcut:'v'];
	[parser registerSwitch:@"help" shortcut:'h'];
	[parser registerOption:@"port" shortcut:'p' requirement:GBValueRequired];
    [parser parseOptionsWithArguments:(char** )argv count:argc block:^(GBParseFlags flags,NSString* option,id value,BOOL* stop) {
        switch (flags) {
		case GBParseFlagUnknownOption:
			(*error) = [self _errorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Unknown option: '%@'",option]];
			(*stop) = YES;
			break;
		case GBParseFlagMissingValue:
			(*error) = [self _errorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Missing value for option: '%@'",option]];
			(*stop) = YES;
			break;
		case GBParseFlagArgument:
			(*stop) = [self _parseAppendArgument:value error:error] ? NO : YES;
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
				if([self _parseOptionPort:value error:error]==NO) {
					(*error) = [self _errorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Missing value for option: '%@'",option]];
				}
			} else {
				(*error) = [self _errorWithCode:kHTTPServerErrorInvalidArgument description:[NSString stringWithFormat:@"Unknown option: '%@'",option]];
				(*stop) = YES;
			}
			break;
		}
    }];
}

-(void)run:(id)sender {
	NSLog(@"Run");
}

-(void)stop:(id)sender {
	NSLog(@"Stop");
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

@end
