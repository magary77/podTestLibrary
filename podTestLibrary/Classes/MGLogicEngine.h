//
//  MGLogicEngine.h
//  DrpadPlayground
//
//  Created by Benjamin on 5/21/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGBlock.h"

@interface MGLogicEngine : NSObject <NSFastEnumeration, MGBLockCollection>

+ (MGLogicEngine *)createEngineFromJSON:(NSDictionary *)json;
- (instancetype)initWithRootBlock:(MGBlock *)root;
- (void)updateModel:(Model *)model;

// Fast enumberation interface:
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len;

@property (nonatomic, strong) MGBlock *root;
@property (nonatomic) NSUInteger count;

@end
