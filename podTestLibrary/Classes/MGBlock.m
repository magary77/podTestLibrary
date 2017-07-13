//
//  MGBlock.m
//  DrpadPlayground
//
//  Created by Benjamin on 5/21/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import "MGBlock.h"

#define NDEBUG

#ifndef NDEBUG
@interface MGModel (testing)
@property (nonatomic) NSInteger counter;
@end
#endif


#pragma mark - MGBlock
@interface MGBlock (protected)

- (void)addBlock:(MGBlock *)block toList:(NSMutableArray *)list;

@property (nonatomic) NSUInteger nextIndex;

@end

@implementation MGBlock {
    NSUInteger _nextIndex;
}

- (instancetype)init {
    if (self = [super init]) {
        _collection = nil;
        _parent = nil;
        _nextIndex = 0;
    }
    return self;
}

- (void)updateModel:(MGModel *)model {
    NSAssert(NO, @"NotImplemented");
}

- (MGBlock *)next {
    NSAssert(NO, @"NotImplemented");
    return nil;
}

- (void)setNextIndex:(NSUInteger)nextIndex {
    _nextIndex = nextIndex;
}

- (NSUInteger)nextIndex {
    return _nextIndex;
}

- (void)addBlock:(MGBlock *)block toList:(NSMutableArray *)list {
    NSAssert(list, @"The request list should not be nil");
    [list addObject: block];
    [block setParent: self];
    
    if (self.collection) {
        [block setCollection: self.collection];
        [self.collection setCount: [self.collection count]+1];
    }
}

@end


#pragma mark - MGRepeatBlock
@interface MGRepeatBlock (private)

@property (nonatomic, strong, readonly) MGBlock *root;

@end

@implementation MGRepeatBlock {
    MGBlock *_root;
}

- (instancetype)initWithRootBlock:(MGBlock *)root {
    if (self = [super init]) {
        NSAssert(root, @"The root should not be nil");
        _root = root;
    }
    return self;
}

- (MGBlock *)root {
    return _root;
}

- (MGBlock *)next {
    MGBlock *next = nil;
    if (self.parent) {
        next = [self.parent next];
    }
    return next;
}

- (void)updateModel:(MGModel *)model {
    [self.root updateModel: model];
}


@end

#pragma mark - MGBooleanBlock
@interface MGBooleanBlock (private)

@property (nonatomic, readonly) NSMutableArray *successBlocks;
@property (nonatomic, readonly) NSMutableArray *failureBlocks;
@property (nonatomic, readonly) BOOL (^decision) (Model *model);

@end

@implementation MGBooleanBlock {
    NSMutableArray *_successBlocks;
    NSMutableArray *_failureBlocks;
    BOOL (^_decision) (Model *model);
}

- (instancetype)initWithDecision:(BOOL (^)(Model *))decision {
    if (self = [super init]) {
        _decision = decision;
        _successBlocks = [[NSMutableArray alloc] init];
        _failureBlocks = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark Private getters/setters
- (NSMutableArray *)successBlocks {
    return _successBlocks;
}

- (NSMutableArray *)failureBlocks {
    return _failureBlocks;
}

- (BOOL (^) (MGModel *model))decision {
    return _decision;
}


#pragma mark Next blocks related:
- (void)addSuccessBlock:(MGBlock *)block {
    [self addBlock: block toList: self.successBlocks];
}

- (void)addFailureBlock:(MGBlock *)block {
    [self addBlock: block toList: self.failureBlocks];
}

- (MGBlock *)next {
    MGBlock *next = nil;
    if (self.nextIndex < [self.successBlocks count]) {
        next = [self.successBlocks objectAtIndex: self.nextIndex];
        self.nextIndex += 1;
    } else if (self.nextIndex < [self.successBlocks count] + [self.failureBlocks count]) {
        next = [self.failureBlocks objectAtIndex: self.nextIndex - [self.successBlocks count]];
        self.nextIndex += 1;
    } else {
        next = [self.parent next];
        self.nextIndex = 0;
    }
    return next;
}

#pragma mark Update model:
- (void)updateModel:(Model *)model {
    BOOL decision;
    @synchronized(model) {
        decision = self.decision(model);
    }
    
#ifndef NDEBUG
    NSLog(@"[MGBlock] booleanAction udpate: %@\n currentThread: %@", self, [NSThread currentThread]);
#endif
    
    if (decision) {
        [model increaseConuter: [self.successBlocks count]];
        [model decreaseCounter: 1];
        if (![model updateProcessFinished]) {
            for (MGBlock *block in self.successBlocks) {
                [block updateModel: model];
            }
        }
    } else {
        [model increaseConuter: [self.failureBlocks count]];
        [model decreaseCounter: 1];
        if (![model updateProcessFinished]) {
            for (MGBlock *block in self.failureBlocks) {
                [block updateModel: model];
            }
        }
    }
}

@end

#pragma mark - MGActionBlock
@interface MGActionBlock (private)

@property (nonatomic, readonly) NSMutableArray *nextBlocks;
@property (nonatomic, readonly) void (^action) (MGModel *model);

@end


@implementation MGActionBlock {
    NSMutableArray *_nextBlocks;
    void (^_action) (MGModel *model);
}


- (instancetype)initWithAction:(void (^)(MGModel *))action {
    if (self = [super init]) {
        _action = action;
        _nextBlocks = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark setters/getters:
- (void (^) (MGModel *model))action {
    return _action;
}

- (NSMutableArray *)nextBlocks {
    return _nextBlocks;
}


#pragma mark Next block related:
- (void)addNextBlock:(MGBlock *)block {
    [self addBlock: block toList: self.nextBlocks];
}

- (MGBlock *)next {
    MGBlock *next = nil;
    if (self.nextIndex < [self.nextBlocks count]) {
        next = [self.nextBlocks objectAtIndex: self.nextIndex];
        self.nextIndex += 1;
    } else {
        next = [self.parent next];
        self.nextIndex = 0;
    }
    return next;
}


#pragma Mark update model:
- (void)updateModel:(MGModel *)model {
    if (self.action != nil) {
        @synchronized(model) {
            self.action(model);
        }
    }
    [model increaseConuter: [self.nextBlocks count]];
    [model decreaseCounter: 1];

#ifndef NDEBUG
    NSLog(@"[MGBlock] actionBlock udpate:   %@\n currentThread: %@", self, [NSThread currentThread]);
#endif
    
    if (![model updateProcessFinished]) {
        for (MGBlock *block in self.nextBlocks) {
            [block updateModel: model];
        }
    }
}

@end
