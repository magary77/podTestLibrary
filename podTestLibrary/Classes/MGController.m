//
//  MGController.m
//  DrpadPlayground
//
//  Created by Benjamin on 5/26/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import "MGController.h"
#import "MGRequestActionBlock.h"

#define NDEBUG

#pragma mark The static method for creating operation queue
static dispatch_queue_t get_operation_processing_queue() {
    static dispatch_queue_t magista_operation_queue;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        magista_operation_queue =
            dispatch_queue_create("drpad.magista.controller.operation.processing",
                                  DISPATCH_QUEUE_SERIAL);
    });
    return magista_operation_queue;
}

#pragma mark - Implementation for the Notification Handler
@implementation MGNotificationHandler

- (instancetype)initWithAction:(BOOL (^)(MGModel *, BOOL *))action correspondingBlock:(MGAsyncActionBlock *)block {
    if (self = [super init]) {
        _correspondingBlock = block;
        _action = action;
    }
    return self;
}

@end


#pragma mark - The private interface
@interface MGController (private)

- (void)processNotification:(NSNotification *)notification;

@property (nonatomic, readonly) MGModel *model;
@property (nonatomic, readonly) MGLogicEngine *engine;
@property (nonatomic, readonly) NSMutableDictionary *notificationHandlers;

@end

#pragma mark - The implementation
@implementation MGController {
    MGLogicEngine *_engine;
    MGModel *_model;
    NSMutableDictionary *_notificationHandlers;
}

- (instancetype)initWithRootBlock:(MGBlock *)root {
    return [self initWithRootBlock: root properties: @{}];
}

- (instancetype)initWithRootBlock:(MGBlock *)root properties:(NSDictionary *)properties {
    if (self = [super init]) {
        // set the properties:
        _model  = [[MGModel alloc] initWithProperties:properties];
        [_model setDelegate: self];
        
        // set the logic engine:
        _engine = [[MGLogicEngine alloc] initWithRootBlock:root];
        for (MGBlock *block in _engine) {
            if ([block isKindOfClass: [MGRequestActionBlock class]]) {
                [(MGRequestActionBlock *)block setResponseHandlerQueue:get_operation_processing_queue()];
            }
        }
        
        // set the dictionary for notification handlers:
        _notificationHandlers = [[NSMutableDictionary alloc] init];
        
        // set the delegates to nil;
        _delegate = nil;
        _renderer = nil;
    }
    return self;
}

- (void)start {
    dispatch_async(get_operation_processing_queue(), ^{
        [self.engine updateModel:self.model];
    });
}


- (void)controllEventToggled:(id)sender {
    if (self.delegate?
        [self.delegate controller:self shouldUpdateWithModel:self.model eventSender:sender] : YES) {
            dispatch_async(get_operation_processing_queue(), ^{
                [self.engine updateModel: self.model];
            });
    }
}

#pragma mark Notification Related
- (void)addHandler:(MGNotificationHandler *)handler forNotificationWithName:(NSString *)name object:(id)object {
    NSAssert(![[self.notificationHandlers allKeys] containsObject:name], @"should not add handler with the notification name which had been registered");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:name object:object];
    [self.notificationHandlers setObject:handler forKey:name];
}

- (void)processNotification:(NSNotification *)notification {
    MGNotificationHandler *handler = [self.notificationHandlers objectForKey:[notification name]];
    MGAsyncActionBlock *asyncActionBlock = [handler correspondingBlock];
    if ([asyncActionBlock currentProcessingModel] == self.model) {
        dispatch_async(get_operation_processing_queue(), ^{
            BOOL abort = NO;
            BOOL continueUpdate = handler.action(self.model, &abort);
            if (abort) {
                NSAssert(NO, @"NotImplementedError");
            }
            if (continueUpdate) {
                [[handler correspondingBlock] restartWithModel:self.model error:nil];
            }
        });
    }
}

#pragma mark The getter for the dispatch queue:
- (dispatch_queue_t)updateOperationQueue {
    return get_operation_processing_queue();
}

#pragma mark Getters for private properties:
- (MGLogicEngine *)engine {
    return _engine;
}

- (MGModel *)model {
    return _model;
}

- (NSMutableDictionary *)notificationHandlers {
    return _notificationHandlers;
}

#pragma mark MGModelDelegate related:
- (void)modelDidFinishUpdate:(MGModel *)model {
    Layout *layout = (self.delegate)?
        [self.delegate controller:self layoutWithModel:self.model] : nil;
    
    if (self.renderer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.renderer updateUIWithLayout: layout];
        });
    }
}


@end
