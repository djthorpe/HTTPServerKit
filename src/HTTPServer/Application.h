
#import <Foundation/Foundation.h>
#import <HTTPServerKit/HTTPServerKit.h>

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
	PGHTTPServer* _server;
}

// properties
@property (retain) NSError* error;
@property (readonly) BOOL showHelp;

// public methods
-(void)setErrorWithCode:(NSInteger)code description:(NSString* )description;
-(BOOL)parseCommandLineArguments:(const char** )argv count:(int)argc;
-(void)run:(id)sender;
-(void)stop:(id)sender;

@end
