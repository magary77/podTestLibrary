//
//  MGBlock.h
//  DrpadPlayground
//
//  Created by Benjamin on 5/21/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGModel.h"

typedef MGModel Model;

#pragma mark - Define the protocol for the block colleaction
@protocol MGBLockCollection <NSObject>

@property (nonatomic) NSUInteger count;

@end

#pragma mark - Define the interface for the block objects
@interface MGBlock : NSObject

- (void)updateModel:(Model *)model;
- (MGBlock *)next;

@property (nonatomic, weak) MGBlock *parent;
@property (nonatomic, weak) id <MGBLockCollection> collection;

@end

#pragma mark - Define the interface for the special block represented the repeat node
@interface MGRepeatBlock : MGBlock

- (instancetype)initWithRootBlock:(MGBlock *)root;

@end


#pragma mark - Define the interface for the (boolean) logic blocks
@interface MGBooleanBlock : MGBlock

- (instancetype)initWithDecision:(BOOL (^) (Model *model))decision;
- (void)addSuccessBlock:(MGBlock *)block;
- (void)addFailureBlock:(MGBlock *)block;

@end

#pragma mark - Define the interface for the action blocks
@interface MGActionBlock : MGBlock

- (instancetype)initWithAction:(void (^) (Model *model))action;
- (void)addNextBlock:(MGBlock *)block;

@end




