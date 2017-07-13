//
//  MGModel.m
//  DrpadPlayground
//
//  Created by Benjamin on 5/21/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import "MGModel.h"

#define COUNTER_INIT_VALUE (1)

//#define NDEBUG

#pragma mark - Private interface for the MGModel
@interface MGModel (private)

+ (NSArray *)serializeKeyPath:(NSString *)keyPath;
+ (NSString *)getParrentKeyPathFromKeyPath:(NSString *)keyPath;
+ (BOOL)stringMatchesIndexPattern:(NSString *)string;

@property (nonatomic) NSUInteger counter;

@end

#pragma mark - Implementations
@implementation MGModel
{
    NSUInteger _counter;
}

- (instancetype)initWithProperties:(NSDictionary *)properties {
    if (self = [super init]) {
        _properties = [[NSMutableDictionary alloc] initWithDictionary: properties];
        _counter = COUNTER_INIT_VALUE;
    }
    return self;
}


#pragma mark Properties Related:
- (NSArray *)allKeys {
    NSArray *keys = nil;
    if (self.properties) {
        keys = [self.properties allKeys];
    }
    return keys;
}

- (void)setModelValue:(id)value forKey:(NSString *)key {
    [self.properties setValue:value forKey:key];
}

- (void)setModelValue:(id)value
           forKeyPath:(NSString *)keyPath
                error:(NSError **)error {
    NSString *parentPath = [MGModel getParrentKeyPathFromKeyPath: keyPath];
    NSString *lastCompoment = [keyPath componentsSeparatedByString: @"."].lastObject;
    if ([parentPath isEqualToString: lastCompoment]) {
        [self setModelValue:value forKey:keyPath];
    } else {
        id parent = [self modelValueForKey:parentPath];
        if ([parent isKindOfClass: [NSDictionary class]]) {
            if (![parent isKindOfClass: [NSMutableDictionary class]]) {
                *error = [[NSError alloc] initWithDomain:MGMODEL_ERROR_DOMAIN
                                                    code:MGModelPropertyNotMutable
                                                userInfo:@{@"keyPath": keyPath}];
                return;
            }
            if ([MGModel stringMatchesIndexPattern:lastCompoment]) {
                *error = [[NSError alloc] initWithDomain:MGMODEL_ERROR_DOMAIN
                                                    code:MGModelRequestKeyTypeError
                                                userInfo:@{@"keyPath": keyPath}];
                return;
            }
            [parent setObject:value forKey:lastCompoment];
            
        } else if ([parent isKindOfClass:[NSArray class]]) {
            if (![parent isKindOfClass:[NSMutableArray class]]) {
                *error = [[NSError alloc] initWithDomain:MGMODEL_ERROR_DOMAIN
                                                    code:MGModelPropertyNotMutable
                                                userInfo:@{@"keyPath": keyPath}];
                return;
            }
            if (![MGModel stringMatchesIndexPattern:lastCompoment]) {
                *error = [[NSError alloc] initWithDomain:MGMODEL_ERROR_DOMAIN
                                                    code:MGModelRequestKeyTypeError
                                                userInfo:@{@"keyPath": keyPath}];
                return;
            }
            // TODO: set object with index?
            [parent addObject:value];
            
        } else {
            *error = [[NSError alloc] initWithDomain:MGMODEL_ERROR_DOMAIN
                                                code:MGModelRequestParentNotFound
                                            userInfo:@{@"keyPath": keyPath}];
            return;
        }
    }
}

- (id)modelValueForKey:(NSString *)key {
    id value = nil;
    if ([[self.properties allKeys] containsObject:key]) {
        value = [self.properties objectForKey:key];
    }
    return value;
}

- (id)modelValueForKeyPath:(NSString *)keyPath {
    NSArray *componenets = [MGModel serializeKeyPath:keyPath];
    id value = self.properties;
    for (id componenet in componenets) {
        if ([value isKindOfClass: [NSArray class]]) {
            if ([componenet isKindOfClass: [NSNumber class]]) {
                int index = (int)[componenet integerValue];
                value = [(NSArray *)value objectAtIndex:index];
            } else {
                return nil;
            }
        } else if ([value isKindOfClass: [NSDictionary class]]) {
            if ([componenet isKindOfClass: [NSString class]]) {
                value = [(NSDictionary *)value objectForKey:componenet];
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
    return value;
}


#pragma mark Counter Related:
- (void)increaseConuter:(NSUInteger)count {
    self.counter = self.counter + count;
}

- (void)decreaseCounter:(NSUInteger)count {
    if (count < self.counter) {
        self.counter = self.counter - count;
    } else {
        self.counter = 0;
        if (self.delegate) {
            [self.delegate modelDidFinishUpdate: self];
        }
    }
}

- (void)startCounter {
    self.counter = COUNTER_INIT_VALUE;
}

- (BOOL)updateProcessFinished {
    return (self.counter == 0);
}

- (void)setCounter:(NSUInteger)counter {
    _counter = counter;
}

- (NSUInteger)counter {
    return _counter;
}

#pragma mark Help functions:
+ (NSArray *)serializeKeyPath:(NSString *)keyPath {
    
    NSArray *components = [keyPath componentsSeparatedByString: @"."];
    NSMutableArray *serialized = [[NSMutableArray alloc] initWithCapacity: [components count]];
    for (NSString *component in components) {
        if ([MGModel stringMatchesIndexPattern: component]) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
            NSNumber *number = [formatter numberFromString: component];
            [serialized addObject: number];
        } else {
            [serialized addObject: component];
        }
    }
    return serialized;
}

// getParrentKeyPathFromKeyPath:
// getting the keyPath of its parent; should reeturn nil if no parent exist (i.e. keyPath = {KEY} instead of {PARENT}.{KEY})
+ (NSString *)getParrentKeyPathFromKeyPath:(NSString *)keyPath {
    NSArray *compoments = [keyPath componentsSeparatedByString: @"."];
    NSMutableString *parent = nil;
    if ([compoments count] > 1) {
        parent = [[NSMutableString alloc] initWithString: compoments[0]];
        for (int i=1; i<[compoments count]-1; i++) {
            [parent appendFormat: @".%@", [compoments objectAtIndex:i]];
        }
    }
    return parent;
}

+ (BOOL)stringMatchesIndexPattern:(NSString *)string {
    NSString *indexPattern = @"^[0-9]+$";
    NSRegularExpression *indexRegex =
        [NSRegularExpression regularExpressionWithPattern: indexPattern
                                                  options: 0
                                                    error: nil];
    return [indexRegex numberOfMatchesInString: string
                                       options: NSMatchingCompleted | NSMatchingHitEnd
                                         range: NSMakeRange(0, [string length])];
    
}

@end
