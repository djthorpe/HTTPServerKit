
#import <Foundation/Foundation.h>
#import "Application.h"

int caughtSignal = 0;
Application* app = nil;

void handleSignal(int signal) {
	caughtSignal = signal;
	if(caughtSignal > 0) {
		[app setErrorWithCode:caughtSignal description:[NSString stringWithFormat:@"Caught signal %d",caughtSignal]];
		[app stop:nil];
	}
}

void setHandleSignal() {
	signal(SIGTERM,handleSignal);
	signal(SIGINT,handleSignal);
	signal(SIGKILL,handleSignal);
	signal(SIGQUIT,handleSignal);
}

int showError() {
	NSError* error = [app error];
	if(error) {
		fprintf(stderr,"Error: %s (domain %s, code %ld)\n",[[error localizedDescription] UTF8String],[[error domain] UTF8String],[error code]);
		return (int)[error code];
	}
	return -1;
}

int showHelp() {
	fprintf(stderr,"TODO: Show help\n");
	return 0;
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		app = [[Application alloc] init];

		// handle termination signals
		setHandleSignal();

		// parse application args
		if([app parseCommandLineArguments:argv count:argc]==NO) {
			return showError();
		}
		// if help, then exit
		if([app showHelp]) {
			return showHelp();
		}

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
		} while(isRunning==YES && caughtSignal==0 && [app error]==nil);

		return showError();
	}
}

