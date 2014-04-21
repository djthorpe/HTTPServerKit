
#import <Foundation/Foundation.h>

@interface PGHTTPPasswordFile : NSObject

// constructors
+(PGHTTPPasswordFile* )passwordFileForPath:(NSString* )path;

// properties
@property (readonly) NSArray* users;

// methods
-(void)setPassword:(NSString* )password forUser:(NSString* )user;

@end
