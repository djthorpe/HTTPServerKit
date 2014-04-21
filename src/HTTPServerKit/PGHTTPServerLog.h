
#import <Foundation/Foundation.h>

@interface PGHTTPServerLog : NSObject

// properties
@property (retain) NSString* hostname;
@property (retain) NSString* user;
@property (retain) NSString* group;
@property (retain) NSString* timestamp;
@property (retain) NSString* request;
@property (assign) NSInteger httpcode;
@property (assign) unsigned long long length;
@property (retain) NSString* referer;
@property (retain) NSString* useragent;

// constructor
-(id)initWithLine:(NSString* )line;

// methods
-(NSDictionary* )dictionary;

@end
