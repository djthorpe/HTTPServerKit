
#import <Foundation/Foundation.h>

@interface PGHTTPPasswordFile : NSObject {
	@private
		NSString* _file;
		BOOL _read;
}

// constructors
+(PGHTTPPasswordFile* )passwordFileForPath:(NSString* )path;

// properties
@property (readonly) NSArray* users;

// methods
-(BOOL)setPassword:(NSString* )password forUser:(NSString* )user;

@end
