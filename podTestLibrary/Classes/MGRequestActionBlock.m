//
//  MGRequestActionBlock.m
//  DrpadPlayground
//
//  Created by Benjamin on 5/29/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import "MGRequestActionBlock.h"

#pragma mark - The MGBlock catagory for the protected properties/methods
@interface MGBlock (requestaction)

- (void)addBlock:(MGBlock *)block toList:(NSMutableArray *)list;

@property (nonatomic) NSUInteger nextIndex;

@end


#pragma mark - Private interface
@interface MGRequestActionBlock ()

- (void)passModelToNextBlocks:(MGModel *)model;

@property (nonatomic, readonly) NSMutableArray *nextBlocks;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, copy) void (^success) (id response, MGModel *model);
@property (nonatomic, copy) void (^failure) (NSError *error, MGModel *model);
@property (nonatomic, copy) NSDictionary* (^getParameters) (MGModel *model);
@property (nonatomic, copy) NSString * (^getRequestURL) (MGModel *model);
@property (nonatomic) MGRequestMethod method;

- (NSString *)requestURLString;

@end

#pragma mark - Implementation
@implementation MGRequestActionBlock

@synthesize nextBlocks = _nextBlocks;
@synthesize url = _url;
@synthesize method = _method;
@synthesize success = _success;
@synthesize failure = _failure;
@synthesize getParameters = _getParameters;
@synthesize getRequestURL = _getRequestURL;

- (instancetype)initWithRequestURLGetter:(NSString *(^)(MGModel *))urlGetter
                                  method:(MGRequestMethod)method
                         parameterGetter:(NSDictionary *(^)(MGModel *))parameterGetter
                                 success:(void (^)(id, MGModel *))success
                                 failure:(void (^)(NSError *, MGModel *))failure {
    if (self = [self initWithMethod:method parameterGetter:parameterGetter success:success failure:failure]) {
        _url = nil;
        _getRequestURL = urlGetter;
    }
    return self;
}

- (instancetype)initWithReqeustURL:(NSString *)url
                            method:(MGRequestMethod)method
                   parameterGetter:(NSDictionary *(^)(MGModel *))getter
                           success:(void (^)(id, MGModel *))success
                           failure:(void (^)(NSError *, MGModel *))failure {
    if (self = [self initWithMethod:method parameterGetter:getter success:success failure:failure]) {
        _url = url;
        _getRequestURL = nil;
    }
    return self;
}

- (instancetype)initWithMethod:(MGRequestMethod)method
               parameterGetter:(NSDictionary *(^)(MGModel *model))getter
                       success:(void (^)(id, MGModel *))success
                       failure:(void (^)(NSError *, MGModel *))failure {
    if (self = [super init]) {
        _nextBlocks = [[NSMutableArray alloc] init];
        _method = method;
        _model = nil;
        _responseHandlerQueue = nil;
        
        // setup the related handlers:
        _getParameters = getter;
        _success = success;
        _failure = failure;
    }
    return self;
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

#pragma mark Update model:
- (void)updateModel:(MGModel *)model {
    self.model = model;
    if (self.requestDelegate) {
        NSDictionary *parameters = nil;
        NSString *requeestURLString = nil;
        @synchronized(model) {
            parameters = self.getParameters(model);
            requeestURLString = [self requestURLString];
        }
        [self.requestDelegate requestBlock: self
                            requestWithURL: requeestURLString
                                    method: self.method
                                parameters: parameters
                                   success: ^(id response) {
                                       dispatch_async([self responseHandlerQueue]?:dispatch_get_main_queue(), ^{
                                           @synchronized(self.model) {
                                               self.success(response, self.model);
                                           }
                                           [self passModelToNextBlocks: self.model];
                                       });
                                   }
                                   failure: ^(NSError *error) {
                                       dispatch_async([self responseHandlerQueue]?:dispatch_get_main_queue(), ^{
                                           @synchronized(self.model) {
                                               self.failure(error, self.model);
                                           }
                                           [self passModelToNextBlocks: self.model];
                                       });
                                   }];
    } else {
        NSAssert(NO, @"The request delegate should not be nil");
    }
}

- (void)passModelToNextBlocks:(MGModel *)model {
    [model increaseConuter: [self.nextBlocks count]];
    [model decreaseCounter: 1];
    
    if (![model updateProcessFinished]) {
        for (MGBlock *block in self.nextBlocks) {
            [block updateModel: model];
        }
    }
    self.model = nil;
}

#pragma mark property getters/setters:
- (NSMutableArray *)nextBlocks {
    return _nextBlocks;
}

- (NSString *)url {
    return _url;
}

- (MGRequestMethod)method {
    return _method;
}

- (void (^) (id response, MGModel *model))success {
    return _success;
}

- (void (^) (NSError *error, MGModel *model))failure {
    return _failure;
}

- (NSDictionary* (^) (MGModel *model))getParameters {
    return _getParameters;
}

- (NSString *)requestURLString {
    NSString *urlString = nil;
    if (self.url) {
        urlString = self.url;
    } else if (self.getRequestURL) {
        urlString = self.getRequestURL(self.model);
    }
    return urlString;
}

@end