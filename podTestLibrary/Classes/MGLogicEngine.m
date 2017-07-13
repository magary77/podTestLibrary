//
//  MGLogicEngine.m
//  DrpadPlayground
//
//  Created by Benjamin on 5/21/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import "MGLogicEngine.h"


@implementation MGLogicEngine

- (instancetype)initWithRootBlock:(MGBlock *)root {
    if (self = [super init]) {
        NSAssert(root, @"The root block should not be nil");
        _root  = root;
        _count = 1;
        [root setCollection: self];
        MGBlock *next= [root next];
        while (next) {
            _count += 1;
            [next setCollection: self];
            next = [next next];
        }
    }
    return self;
}

+ (MGLogicEngine *)createEngineFromJSON:(NSDictionary *)json {
    @throw [NSException exceptionWithName: @"NotImplemented"
                                   reason: @"createEngineFromJSON"
                                 userInfo: nil];
    NSAssert(NO, @"NotImplemented: createEngineFromJSON");
    return nil;
}

- (void)updateModel:(Model *)model {
    [model startCounter];
    [self.root updateModel: model];
}

// Fast enumberation related interface:
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    // The initailization state:
    if (state->state == 0) {
        state->mutationsPtr = &_count;
        state->extra[0] = (unsigned long)_root;
        state->state = 1;
    }
    
    // TODO: should load the previous block from the state->extra[0]
    MGBlock *current = (__bridge MGBlock *)(void *)(state->extra[0]);
    NSUInteger count = 0;
    while (current && count < len) {
        buffer[count] = current;
        count++;
        current = [current next];
    }
    state->extra[0] = (unsigned long)current;
    state->itemsPtr = buffer;
    
    return count;
}

@end
