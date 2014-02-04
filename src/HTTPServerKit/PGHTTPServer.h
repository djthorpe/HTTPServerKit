
#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////

typedef enum {
	PGHTTPServerStateUnknown,
	PGHTTPServerStateStarted,
	PGHTTPServerStateStopped,
} PGHTTPServerStateType;

typedef enum {
	PGHTTPServerErrorUnknown = 100,
	PGHTTPServerErrorNetwork = 101,
	PGHTTPServerErrorTemplate = 102
} PGHTTPServerErrorType;

////////////////////////////////////////////////////////////////////////////////

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
		int _pid;
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
@property (readonly) int pid;

// methods
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot;
-(BOOL)stop;

@end
