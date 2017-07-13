//
//  MGController.h
//  DrpadPlayground
//
//  Created by Benjamin on 5/26/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGAsyncActionBlock.h"
#import "MGModel.h"
#import "MGLogicEngine.h"

typedef NSDictionary Layout;

@class MGController;

#pragma mark - Define the delegate protocol:
@protocol MGControllerDelegate

@required

- (BOOL)controller:(MGController *)controller shouldUpdateWithModel:(MGModel *)model eventSender:(id)sender;
- (Layout *)controller:(MGController *)controller layoutWithModel:(MGModel *)model;

@end

#pragma mark - Define the rederer protocol:
@protocol MGRenderer

- (void)updateUIWithLayout:(Layout *)layout;

@end

#pragma mark - Define the interface for the notification handler:
@interface MGNotificationHandler : NSObject

- (instancetype)initWithAction:(BOOL(^)(MGModel *model, BOOL *abort))action correspondingBlock:(MGAsyncActionBlock *)block;
@property (nonatomic, readonly) BOOL (^ action) (MGModel *model, BOOL *abort);
@property (nonatomic, readonly) MGAsyncActionBlock *correspondingBlock;

@end


#pragma mark - Define the MGController interface:
@interface MGController : NSObject <MGModelDelegate>

- (instancetype)initWithRootBlock:(MGBlock *)root;
- (instancetype)initWithRootBlock:(MGBlock *)root properties:(NSDictionary *)properties;

- (void)start;
- (void)controllEventToggled:(id)sender;
- (void)modelDidFinishUpdate:(MGModel *)model;
- (void)addHandler:(MGNotificationHandler *)handler forNotificationWithName:(NSString *)name object:(id)object;


@property (nonatomic, weak) id <MGControllerDelegate> delegate;
@property (nonatomic, weak) id <MGRenderer> renderer;

/*
 * updateOperationQueue: the dispatch queue for running the decision/action blocks
 */
@property (nonatomic, strong, readonly) dispatch_queue_t updateOperationQueue;

/*
 * responseHandlerQueue: the dispatch queue for the reponse handelr of api reqeusts
 */
@property (nonatomic, strong) dispatch_queue_t responseHandlerQueue;

@end
