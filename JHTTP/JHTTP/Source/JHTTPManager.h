//
//  JHTTPManager.h
//  JHTTP
//
//  Created by jams on 2020/9/7.
//  Copyright © 2020 jams. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^JHTTPCompletionBlock)(id _Nullable response, NSError *_Nullable error);
typedef void(^JHTTPProgressBlock)(NSProgress *_Nullable progress);

FOUNDATION_EXTERN NSErrorDomain const JHTTPErrorDomain;

@interface JHTTPManager : NSObject

+ (instancetype)shared;

- (void)GET:(NSString *)url params:(NSDictionary *_Nullable)params header:(NSDictionary *_Nullable)header completion:(JHTTPCompletionBlock _Nullable)completionBlock;

@end

NS_ASSUME_NONNULL_END
