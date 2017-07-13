//
//  MGAsyncActionBlock.h
//  Pods
//
//  Created by Benjamin on 9/17/15.
//
//

#import "MGBlock.h"
#import "MGModel.h"

#pragma mark - Define the interface for MGAsyncActionNotificationHandler
@interface MGAsyncActionNotificationHandler: NSObject

- (instancetype)initWithBlock:(void(^)(MGModel *))block;

@property (nonatomic, readonly) void (^block) (MGModel *);

@end


#pragma mark - Define the interface for MGAsyncActionBlock
@interface MGAsyncActionBlock : MGBlock

- (void)restartWithModel:(MGModel *)model error:(NSError **)error;

@property (nonatomic, readonly) NSMutableArray* nextBlocks;
@property (nonatomic, readonly) void (^asyncAction) (MGModel *model, MGAsyncActionBlock *block);
@property (nonatomic, readonly) MGModel *currentProcessingModel;

- (instancetype)initWithAction:(void(^)(MGModel *, MGAsyncActionBlock *))action;


@end
