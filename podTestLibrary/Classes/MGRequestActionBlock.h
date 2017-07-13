//
//  MGRequestActionBlock.h
//  DrpadPlayground
//
//  Created by Benjamin on 5/29/15.
//  Copyright (c) 2015 Benjamin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGBlock.h"

@class MGRequestActionBlock;

typedef enum request_method {
    GET,
    POST,
    PUT,
    DELETE
} MGRequestMethod;

#pragma mark The actionBlock delegate: will perform the requesting action
@protocol MGRequestActionBlockDelegate

- (void)requestBlock:(MGRequestActionBlock *)block
      requestWithURL:(NSString *)url
              method:(MGRequestMethod)method
          parameters:(NSDictionary *)parameters
             success:(void (^) (id response))success
             failure:(void (^) (NSError *error))failure;

@end

#pragma mark The public interface of the requestActionBlock
@interface MGRequestActionBlock : MGBlock

- (instancetype)initWithRequestURLGetter:(NSString *(^)(MGModel *model))urlGetter
                                  method:(MGRequestMethod)method
                         parameterGetter:(NSDictionary * (^)(MGModel *model))parameterGetter
                                 success:(void (^)(id response, MGModel *model))success
                                 failure:(void (^)(NSError *error, MGModel *model))failure;

- (instancetype)initWithReqeustURL:(NSString *)url
                            method:(MGRequestMethod)method
                   parameterGetter:(NSDictionary * (^)(MGModel *model))getter
                           success:(void (^)(id response, MGModel *model))success
                           failure:(void (^)(NSError *error, MGModel *model))failure;

- (void)addNextBlock:(MGBlock *)block;
- (MGBlock *)next;

@property (nonatomic, weak) id <MGRequestActionBlockDelegate> requestDelegate;
@property (nonatomic, strong) MGModel *model;
@property (nonatomic) dispatch_queue_t responseHandlerQueue;

@end
