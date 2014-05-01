
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
		-(void)serverStopped:(PGHTTPServer* )server;
		-(void)server:(PGHTTPServer* )server log:(PGHTTPServerLog* )log;
		-(void)server:(PGHTTPServer* )server error:(NSError* )error;
@end

@interface PGHTTPServer : NSObject <NSNetServiceDelegate> {
	@private
		NSUInteger _port;
		NSTask* _task;
		NSNetService* _bonjour;
		NSString* _documentRoot;
}

// constructor
+(PGHTTPServer* )server;

// properties
@property (assign) id<PGHTTPServerDelegate> delegate;
@property (retain) NSString* bonjourName;
@property (retain) NSString* bonjourType;
@property (readonly) NSUInteger port;
@property (readonly) int pid;
@property (readonly) NSString* documentRoot;
@property (readonly) PGHTTPPasswordFile* globalPasswordFile;

// methods
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot;
-(BOOL)startWithDocumentRoot:(NSString* )documentRoot port:(int)port;
-(BOOL)stop;

@end
