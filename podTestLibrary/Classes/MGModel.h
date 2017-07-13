//
//  MGModel.h
//  DrpadPlayground
//
//  Created by Benjamin on 5/21/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import <Foundation/Foundation.h>
#define MGMODEL_ERROR_DOMAIN @"drpad.Magista"

@class MGModel;

typedef enum mg_model_exception {
    MGModelPropertyNotMutable,
    MGModelRequestKeyTypeError,
    MGModelRequestParentNotFound,
    MGModelUnknownException
} MGModelException;

#pragma mark - Define the MGModelDelegate
@protocol MGModelDelegate <NSObject>

- (void)modelDidFinishUpdate:(MGModel *)model;

@end

#pragma mark - Define the interface for the MGModel
@interface MGModel : NSObject

- (instancetype)initWithProperties:(NSDictionary *)properties;

#pragma mark Properties related:

- (void)setModelValue:(id)value forKey:(NSString *)key;
- (void)setModelValue:(id)value forKeyPath:(NSString *)keyPath error:(NSError **)error;

- (id)modelValueForKey:(NSString *)key;
- (id)modelValueForKeyPath:(NSString *)keyPath;
- (NSArray *)allKeys;

#pragma mark Counter related:
- (void)increaseConuter:(NSUInteger)count;
- (void)decreaseCounter:(NSUInteger)count;
- (BOOL)updateProcessFinished;
- (void)startCounter;

@property (nonatomic) NSInteger state;
@property (nonatomic, readonly) NSMutableDictionary *properties;
@property (nonatomic, weak) id <MGModelDelegate> delegate;

@end
