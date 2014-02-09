
#import <Foundation/Foundation.h>
#import "Application.h"

int caughtSignal = 0;
Application* app = nil;

void handleSignal(int signal) {
	caughtSignal = signal;
	if(caughtSignal > 0) {
		[app setReturnCode:caughtSignal];
		[app stop:nil];
	}
}

void setHandleSignal() {
	signal(SIGTERM,handleSignal);
	signal(SIGINT,handleSignal);
	signal(SIGKILL,handleSignal);
	signal(SIGQUIT,handleSignal);
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		app = [[Application alloc] init];

		// handle termination signals
		setHandleSignal();

		// parse application args
		NSError* error = nil;
		[app parseCommandLineArguments:argv count:argc error:&error];

		// create the timer to fire the run method on start of run loop
		[NSTimer scheduledTimerWithTimeInterval:0.0 target:app selector:@selector(run:) userInfo:nil repeats:NO];

		// new autorelease pool every 5 mins
		double resolution = 300.0;
		BOOL isRunning;
		do {
			@autoreleasepool {
				NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
				isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
			}
		} while(isRunning==YES && caughtSignal==0 && [app returnCode]==0);

		if([app returnCode]) {
			fprintf(stderr,"Exit with code: %d\n",[app returnCode]);
		}
		return [app returnCode];
	}
}

/*
		switch([app returnCode]) {
			case 0:
				// no error
				break;
			case PGMediaApplicationErrorHelp:
				fprintf(stderr,"%s\n\n",[[app longSyntaxMessage] UTF8String]);
				return [app returnCode];
			default: {
				const char* domain = [[error domain] UTF8String];
				const char* description = [[error localizedDescription] UTF8String];
				fprintf(stderr,"Error: %s (%s code %ld)\n\n\t%s\n\n",description,domain,(long)[error code],[[app shortSyntaxMessage] UTF8String]);
				return [app returnCode];
			}
		}
*/

