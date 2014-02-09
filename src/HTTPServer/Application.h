
#import <Foundation/Foundation.h>

extern NSString* const kHTTPServerErrorDomain;
enum {
	kHTTPServerErrorUnknown = -100,
	kHTTPServerErrorInvalidArgument = -101,
};


@interface Application : NSObject {
	BOOL _flag_verbose;
	BOOL _flag_help;
	NSUInteger _flag_port;
	NSString* _flag_docroot;
}

// properties
@property int returnCode;

// public methods
-(void)parseCommandLineArguments:(const char** )argv count:(int)argc error:(NSError** )error;
-(void)run:(id)sender;
-(void)stop:(id)sender;

@end
