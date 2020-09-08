//
//  ViewController.m
//  JHTTP
//
//  Created by jams on 2020/9/7.
//  Copyright © 2020 jams. All rights reserved.
//

#import "ViewController.h"
#import "JHTTPManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self fetchFilms];
}


- (void)fetchFilms {
    NSString *filmUrl = @"https://swapi.dev/api/films";
    NSDictionary *params = @{@"search" : @"Hope"};
    NSDictionary *headers = @{@"User-Agent" : @"com.jams.http"};
    [[JHTTPManager shared] GET:filmUrl params:params header:headers completion:^(id  _Nullable response, NSError * _Nullable error) {
        NSLog(@"fetch films: %@", response);
    }];
}

@end
