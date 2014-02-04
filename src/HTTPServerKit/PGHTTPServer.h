
#import <Foundation/Foundation.h>

typedef enum {
	PGHTTPServerStateUnknown,
	PGHTTPServerStateStarted,
	PGHTTPServerStateStopped,
} PGHTTPServerStateType;

@class PGHTTPServer;

@protocol PGHTTPServerDelegate <NSObject>
	@required
		-(void)server:(PGHTTPServer* )server startedWithURL:(NSURL* )url;
		-(void)server:(PGHTTPServer* )server stoppedWithReturnCode:(int)returnCode;
@end

@interface PGHTTPServer : NSObject <NSNetServiceDelegate> {
	@private
		PGHTTPServerStateType _state;
		NSString* _path;
		NSUInteger _pid;
		int _port;
		NSNetService* _bonjour;
}

// constructor
+(PGHTTPServer* )serverWithDataPath:(NSString* )thePath;

// properties
@property (assign) id<PGHTTPServerDelegate> delegate;
@property (retain) NSString* bonjourName;
@property (retain) NSString* bonjourType;
@property (assign) int port;
@property (readonly) PGHTTPServerStateType state;
@property (readonly) int pid;
@property (readonly) NSURL* URL;

// methods
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot;
-(BOOL)stop;

@end
