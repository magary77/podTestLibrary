//
//  MGAsyncActionBlock.m
//  Pods
//
//  Created by Benjamin on 9/17/15.
//
//

#import "MGAsyncActionBlock.h"

@interface MGAsyncActionBlock ()

@property (nonatomic) NSUInteger nextIndex;
@property (nonatomic, strong) MGModel *currentProcessingModel;

@end



@implementation MGAsyncActionBlock

- (instancetype)initWithAction:(void (^)(Model *, MGAsyncActionBlock *block))action {
    if (self = [super init]) {
        _nextBlocks = [[NSMutableArray alloc] init];
        _asyncAction = action;
    }
    return self;
}


- (void)updateModel:(Model *)model {
    NSAssert(self.asyncAction, @"The asyc action should not be nil");
    NSAssert(self.currentProcessingModel == nil, @"The current processing model should be nil");
    
    @synchronized(model) {
        [self setCurrentProcessingModel:model];
        self.asyncAction(model, self);
    }
    
}

- (void)restartWithModel:(MGModel *)model error:(NSError *__autoreleasing *)error {
    if (model == self.currentProcessingModel) {
        self.currentProcessingModel = nil;
        [model increaseConuter:[self.nextBlocks count]];
        [model decreaseCounter:1];
        if (![model updateProcessFinished]) {
            for (MGBlock *block in self.nextBlocks) {
                [block updateModel:model];
            }
        }
    } else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"The request mode does not match with the async action block"};
        *error = [[NSError alloc] initWithDomain:@"magista.mgasyncactionblock.restart" code:100 userInfo:userInfo];
    }
}

#pragma mark Next block related:
- (void)addBlock:(MGBlock *)block toList:(NSMutableArray *)list {
    NSAssert(list, @"The request list should not be nil");
    [list addObject: block];
    [block setParent: self];
    
    if (self.collection) {
        [block setCollection: self.collection];
        [self.collection setCount: [self.collection count]+1];
    }
}

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

@end
