
#import <HTTPServerKit/HTTPServerKit.h>

@implementation PGHTTPServerLog

////////////////////////////////////////////////////////////////////////////////
#pragma mark PRIVATE METHODS

-(BOOL)_parseLogline:(NSString* )line {
	NSScanner* scanner = [NSScanner scannerWithString:line];
	NSParameterAssert(scanner);
	enum {
		STATE_INIT = 0, STATE_USER = 1, STATE_GROUP = 2, STATE_DATE = 3,
		STATE_REQUEST = 4, STATE_HTTPCODE = 5, STATE_LENGTH = 6, STATE_REFERER = 7,
		STATE_USERAGENT = 8, STATE_END = 9, STATE_ERROR = -1
	} state = STATE_INIT;
	NSString* tmp = nil;
	NSInteger tmp2;
	unsigned long long tmp3;
	while([scanner isAtEnd]==NO) {
		switch(state) {
			case STATE_INIT: // scan hostname
				if([scanner scanUpToString:@" " intoString:&tmp]==YES) {
					[self setHostname:[tmp copy]];
					state = STATE_USER;
					[scanner scanString:@" " intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_USER:
				if([scanner scanUpToString:@" " intoString:&tmp]==YES) {
					[self setUser:[tmp copy]];
					state = STATE_GROUP;
					[scanner scanString:@" " intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_GROUP:
				if([scanner scanUpToString:@" " intoString:&tmp]==YES) {
					[self setGroup:[tmp copy]];
					state = STATE_DATE;
					[scanner scanString:@" " intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_DATE:
				if([scanner scanString:@"[" intoString:nil]==NO) {
					state = STATE_ERROR;
				}
				if([scanner scanUpToString:@"]" intoString:&tmp]==YES) {
					[self setTimestamp:[tmp copy]];
					state = STATE_REQUEST;
					[scanner scanString:@"]" intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_REQUEST:
				if([scanner scanString:@"\"" intoString:nil]==NO) {
					state = STATE_ERROR;
				}
				if([scanner scanString:@"\"" intoString:nil]==YES) {
					[self setRequest:@""];
					state = STATE_HTTPCODE;
				} else if([scanner scanUpToString:@"\"" intoString:&tmp]==YES) {
					[self setRequest:[tmp copy]];
					state = STATE_HTTPCODE;
					[scanner scanString:@"\"" intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_HTTPCODE:
				if([scanner scanInteger:&tmp2]==NO) {
					state = STATE_ERROR;
				} else {
					[self setHttpcode:tmp2];
					state = STATE_LENGTH;
				}
				break;
			case STATE_LENGTH:
				if([scanner scanUnsignedLongLong:&tmp3]==NO) {
					state = STATE_ERROR;
				} else {
					[self setLength:tmp3];
					state = STATE_REFERER;
				}
				break;
			case STATE_REFERER:
				if([scanner scanString:@"\"" intoString:nil]==NO) {
					state = STATE_ERROR;
				}
				if([scanner scanString:@"\"" intoString:nil]==YES) {
					[self setReferer:@""];
					state = STATE_USERAGENT;
				} else if([scanner scanUpToString:@"\"" intoString:&tmp]==YES) {
					[self setReferer:[tmp copy]];
					state = STATE_USERAGENT;
					[scanner scanString:@"\"" intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_USERAGENT:
				if([scanner scanString:@"\"" intoString:nil]==NO) {
					state = STATE_ERROR;
				}
				if([scanner scanString:@"\"" intoString:nil]==YES) {
					[self setUseragent:@""];
					state = STATE_END;
				} else if([scanner scanUpToString:@"\"" intoString:&tmp]==YES) {
					[self setUseragent:[tmp copy]];
					state = STATE_END;
					[scanner scanString:@"\"" intoString:nil];
				} else {
					state = STATE_ERROR;
				}
				break;
			case STATE_END:
				[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
				break;
			case STATE_ERROR:
			default:
#ifdef DEBUG
				NSLog(@"Scan failed, unexpected character: %@",line);
#endif
				return NO;
		}
	}
	
	if(state != STATE_END) {
#ifdef DEBUG
		NSLog(@"Scan failed, unexpected end: %@",line);
#endif
		return NO;
	}
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark CONSTRUCTOR

-(id)init {
	return nil;
}

-(id)initWithLine:(NSString* )line {
	self = [super init];
	if(self) {
		BOOL isSuccess = [self _parseLogline:line];
		if(isSuccess==NO) {
			return nil;
		}
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark PUBLIC METHODS

-(NSDictionary* )dictionary {
	return @{
		@"hostname": [self hostname],
		@"user": [self user],
		@"group": [self group],
		@"request": [self request],
		@"httpcode": [NSNumber numberWithInteger:[self httpcode]],
		@"length": [NSNumber numberWithUnsignedLongLong:[self length]],
		@"referer": [self referer],
		@"useragent": [self useragent],
		@"timestamp": [self timestamp],
	};
}

-(NSString* )description {
	return [[self dictionary] description];
}

@end
