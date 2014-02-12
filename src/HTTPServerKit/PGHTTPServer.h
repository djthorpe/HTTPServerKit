
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
		NSUInteger _port;
		NSNetService* _bonjour;
		NSError* _error;
}

// constructor
+(PGHTTPServer* )serverWithDataPath:(NSURL* )url;

// properties
@property (assign) id<PGHTTPServerDelegate> delegate;
@property (retain) NSString* bonjourName;
@property (retain) NSString* bonjourType;
@property (assign) NSUInteger port;
@property (readonly) NSInteger pid;

// methods
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot;
-(BOOL)stop;

@end
