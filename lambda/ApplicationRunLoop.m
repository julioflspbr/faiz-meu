//
//  ApplicationRunLoop.m
//  FaizMeuLambda
//
//  Created by Júlio César Flores on 24/07/2022.
//

#import "ApplicationRunLoop.h"

#include <pthread.h>

typedef struct {
	pthread_t thread;
	CFRunLoopRef runLoop;
	CFRunLoopSourceRef taskSource;
	ApplicationExecution __strong task;
	ApplicationRunLoop * __weak application;
} ApplicationThreadContext;

#pragma mark - Forward declarations
@interface ApplicationRunLoop () {
	ApplicationThreadContext context;
}

-(void)consumeTask;
-(void)dealloc;

@end

void * applicationThreadMain(void * info);
void performRunLoopTask(void * info);

#pragma mark - C methods implementations
void * applicationThreadMain(void * info) {
	ApplicationThreadContext * context = (ApplicationThreadContext *)info;

	context->runLoop = CFRunLoopGetCurrent();

	CFRunLoopSourceContext taskSourceContext = { 0, (__bridge void*)context->application, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &performRunLoopTask };
	context->taskSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &taskSourceContext);
	if (!context->taskSource) {
		[NSException raise:@"BadTaskSourceCreation" format:@"Not possible to create the Run Loop Execution Source. This does not allow execution on demand. The application is pointless without it. Terminating."];
	}
	CFRunLoopAddSource(context->runLoop, context->taskSource, kCFRunLoopDefaultMode);

	CFRunLoopRun();
	return NULL;
}

void performRunLoopTask(void * info) {
	ApplicationRunLoop * runLoop = (__bridge ApplicationRunLoop *)info;
	[runLoop consumeTask];
}

#pragma mark - Objective-C implementations
@implementation ApplicationRunLoop

- (instancetype)init {
	self = [super init];
	if (self) {
		context.application = self;
		int threadCreationError = pthread_create(&context.thread, NULL, &applicationThreadMain, &context);
		if (threadCreationError) {
			[NSException raise:@"BadThreadCreation" format:@"Not possible to create the Application Execution Thread. This does not allow execution on demand. The application is pointless without it. Terminating."];
		}
	}
	return self;
}

- (void)execute:(ApplicationExecution)block {
	context.task = block;
	CFRunLoopSourceSignal(context.taskSource);
	CFRunLoopWakeUp(context.runLoop);
}

-(void)consumeTask {
	if (context.task) context.task();
	context.task = nil;
}

- (void)stop {
	CFRunLoopSourceInvalidate(context.taskSource);
	CFRelease(context.taskSource);
	CFRunLoopStop(context.runLoop);

	int threadTerminationError = pthread_join(context.thread, NULL);
	if (threadTerminationError) {
		[NSException raise:@"BadThreadTermination" format:@"The application is having a hard time terminating the Application Execution Thread. The process is being terminated in a non-clean state."];
	}
}

- (void)dealloc {
	[self stop];
}

@end
