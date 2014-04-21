
#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////

typedef enum {
	PGHTTPServerErrorUnknown = 100,
	PGHTTPServerErrorNetwork = 101
} PGHTTPServerErrorType;

////////////////////////////////////////////////////////////////////////////////

@class PGHTTPServer;

@protocol PGHTTPServerDelegate <NSObject>
	@optional
		-(void)server:(PGHTTPServer* )server startedWithURL:(NSURL* )url;
		-(void)server:(PGHTTPServer* )server stoppedWithReturnCode:(int)returnCode;
		-(void)server:(PGHTTPServer* )server log:(PGHTTPServerLog* )log;
@end

@interface PGHTTPServer : NSObject <NSNetServiceDelegate> {
	@private
		NSUInteger _port;
		NSTask* _task;
		NSNetService* _bonjour;
}

// constructor
+(PGHTTPServer* )server;

// properties
@property (assign) id<PGHTTPServerDelegate> delegate;
@property (retain) NSString* bonjourName;
@property (retain) NSString* bonjourType;
@property (readonly) NSUInteger port;
@property (readonly) int pid;

// methods
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot;
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot port:(int)port;
-(BOOL)stop;

@end
