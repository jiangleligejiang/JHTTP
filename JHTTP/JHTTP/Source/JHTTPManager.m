//
//  JHTTPManager.m
//  JHTTP
//
//  Created by jams on 2020/9/7.
//  Copyright © 2020 jams. All rights reserved.
//

#import "JHTTPManager.h"

NSErrorDomain const JHTTPErrorDomain = @"JHTTPErrorDomain";

@interface JHTTPManager () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *complectionBlockDict;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableData *> *responseDataDict;

@end

@implementation JHTTPManager

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static JHTTPManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[JHTTPManager alloc] init];
        [manager setup];
    });
    return manager;
}

- (void)setup {
    self.complectionBlockDict = [NSMutableDictionary dictionary];
    self.responseDataDict = [NSMutableDictionary dictionary];
}

- (void)GET:(NSString *)url params:(NSDictionary *)params header:(NSDictionary *)header completion:(JHTTPCompletionBlock)completionBlock {
    if (![url isKindOfClass:[NSString class]] || url.length == 0) {
        [self handleFailedReason:@"url不为`NSString`类型或url为空" code:-1 completionBlock:completionBlock];
        return;
    }
    
    NSURL *reqeustURL = nil;
    if ([params isKindOfClass:[NSDictionary class]] && params.count > 0) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithString:url];
        if (urlComponents) {
            NSMutableArray *queryItems = [NSMutableArray arrayWithCapacity:params.count];
            __weak typeof(self) weakSelf = self;
            [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
                if ([key isKindOfClass:[NSString class]] && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
                    NSString *valueStr = [value isKindOfClass:[NSNumber class]] ? [(NSNumber *)value stringValue] : value;
                    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:valueStr];
                    [queryItems addObject:item];
                } else {
                    [weakSelf handleFailedReason:@"params中的key必须为`NSString`类型，value必须为`NSString`或`NSNumber`类型" code:-1 completionBlock:completionBlock];
                    *stop = YES;
                    return;
                }
            }];
            urlComponents.queryItems = [queryItems copy];
            reqeustURL = urlComponents.URL;
        }
    } else {
        reqeustURL = [NSURL URLWithString:url];
    }
    
    if (![reqeustURL isKindOfClass:[NSURL class]]) {
        [self handleFailedReason:@"url转换为`NSURL`错误" code:-1 completionBlock:completionBlock];
        return;
    }
    

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:reqeustURL];
    request.HTTPMethod = @"GET";
    
    if ([header isKindOfClass:[NSDictionary class]] && header.count > 0) {
        __weak typeof(self) weakSelf = self;
        [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
                [request setValue:value forHTTPHeaderField:key];
            } else {
                [weakSelf handleFailedReason:@"header中的key必须为`NSString`类型，value必须为`NSString`或`NSNumber`类型" code:-1 completionBlock:completionBlock];
                *stop = YES;
                return;
            }
        }];
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    
    if (completionBlock) {
        [self.complectionBlockDict setObject:completionBlock forKey:@(dataTask.taskIdentifier)];
    }
    
    [dataTask resume];
}

- (void)handleFailedReason:(NSString *)reason code:(NSInteger)code completionBlock:(JHTTPCompletionBlock)completionBlock {
    NSError *error = [NSError errorWithDomain:JHTTPErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : reason}];
    if (completionBlock) {
        completionBlock(nil, error);
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.responseDataDict setObject:[NSMutableData data] forKey:@(dataTask.taskIdentifier)];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSMutableData *responseData = [self.responseDataDict objectForKey:@(dataTask.taskIdentifier)];
    if ([responseData isKindOfClass:[NSMutableData class]] && data) {
        [responseData appendData:data];
    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self handleCompletionWithIdentifier:task.taskIdentifier response:nil error:error];
    } else {
        NSMutableData *responseData = [self.responseDataDict objectForKey:@(task.taskIdentifier)];
        if ([responseData isKindOfClass:[NSMutableData class]]) {
            NSError *parserError;
            id responseObj = [NSJSONSerialization JSONObjectWithData:[responseData copy] options:NSJSONReadingMutableContainers error:&parserError];
            if (parserError) {
                [self handleCompletionWithIdentifier:task.taskIdentifier response:responseObj error:parserError];
            } else {
                [self handleCompletionWithIdentifier:task.taskIdentifier response:responseObj error:nil];
            }
        }
    }
}

- (void)handleCompletionWithIdentifier:(NSUInteger)taskIdentifier response:(id)response error:(NSError *)error {
    JHTTPCompletionBlock completionBlock = [self.complectionBlockDict objectForKey:@(taskIdentifier)];
    if (completionBlock) {
        completionBlock(response, error);
        [self.complectionBlockDict removeObjectForKey:@(taskIdentifier)];
    }
}

- (NSError *)errorWithReason:(NSString *)reason code:(NSInteger)code {
    return [NSError errorWithDomain:JHTTPErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : reason}];
}

@end
