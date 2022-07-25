//
//  ApplicationRunLoop.m
//  FaizMeuLambda
//
//  Created by Júlio César Flores on 24/07/2022.
//

#import "ApplicationRunLoop.h"

@interface ApplicationRunLoop () {
	CFRunLoopRef runLoop;
	CFRunLoopSourceRef taskSource;
	ApplicationExecution __strong task;
}

-(void)consumeTask;
-(void)dealloc;

@end

void performRunLoopTask(void * info) {
	ApplicationRunLoop * runLoop = (__bridge ApplicationRunLoop *)info;
	[runLoop consumeTask];
}

@implementation ApplicationRunLoop

- (instancetype)init {
	self = [super init];
	if (self) {
		runLoop = CFRunLoopGetCurrent();

		CFRunLoopSourceContext taskSourceContext = { 0, (__bridge void*)self, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &performRunLoopTask };
		taskSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &taskSourceContext);
		if (!taskSource) {
			[NSException raise:@"BadTaskSourceCreation" format:@"Not possible to create the Run Loop execution source. this does not allow execution on demand. The application is pointless without it. Terminating."];
		}
		CFRunLoopAddSource(runLoop, taskSource, kCFRunLoopDefaultMode);

		CFRunLoopRun();
	}
	return self;
}

- (void)execute:(ApplicationExecution)block {
	task = block;
	CFRunLoopSourceSignal(taskSource);
	CFRunLoopWakeUp(runLoop);
}

-(void)consumeTask {
	if (task) task();
	task = nil;
}

- (void)stop {
	CFRunLoopSourceInvalidate(taskSource);
	CFRelease(taskSource);
	CFRunLoopStop(runLoop);
}

- (void)dealloc {
	[self stop];
}

@end
