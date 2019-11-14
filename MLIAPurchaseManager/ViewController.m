//
//  ViewController.m
//  MLIAPurchaseManager
//
//  Created by mali on 16/5/14.
//  Copyright © 2016年 mali. All rights reserved.
//

#import "ViewController.h"
#import "MLIAPManager.h"
#import <StoreKit/StoreKit.h>
//最好保存在服务器上，就可以不更新版本实现在Apple后台动态配置商品了
static NSString * const productId = @"cn.189.6yuan";

@interface ViewController() <MLIAPManagerDelegate,SKStoreProductViewControllerDelegate>

@end

@implementation ViewController

#pragma mark - ================ LifeCycle =================

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    refreshBtn.frame = CGRectMake(100, 100, 100, 44);
    [refreshBtn setTitle:@"刷新凭证" forState:UIControlStateNormal];
    [refreshBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    refreshBtn.backgroundColor = [UIColor blueColor];
    [refreshBtn addTarget:self action:@selector(refreshBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:refreshBtn];
    
    [MLIAPManager sharedManager].delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - ================ Touches =================

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[MLIAPManager sharedManager] requestProductWithId:productId];
}

#pragma mark - ================ Actions =================

- (void)refreshBtnClicked {
//    [[MLIAPManager sharedManager] refreshReceipt];
    SKStoreProductViewController * vc = [[SKStoreProductViewController alloc] init];
    vc.delegate = self;
    NSDictionary * dic = @{SKStoreProductParameterITunesItemIdentifier:@"1290653519"};
    [vc loadProductWithParameters:dic completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (result) {
            
        }
    }];
    [self presentViewController:vc animated:YES completion:nil];
}
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ================ MLIAPManager Delegate =================

- (void)receiveProduct:(SKProduct *)product {
    
    if (product != nil) {
        //购买商品
        if (![[MLIAPManager sharedManager] purchaseProduct:product]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"失败" message:@"您禁止了应用内购买权限,请到设置中开启" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
            [alert show];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"失败" message:@"无法连接App store!" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)successedWithReceipt:(NSData *)transactionReceipt {
    NSLog(@"购买成功");

    NSString  *transactionReceiptString = [transactionReceipt base64EncodedStringWithOptions:0];
    
    if ([transactionReceiptString length] > 0) {
        [self requestData:transactionReceiptString];
        // 向自己的服务器验证购买凭证（此处应该考虑将凭证本地保存,对服务器有失败重发机制）
        /**
         服务器要做的事情:
         接收ios端发过来的购买凭证。
         判断凭证是否已经存在或验证过，然后存储该凭证。
         将该凭证发送到苹果的服务器验证，并将验证结果返回给客户端。
         如果需要，修改用户相应的会员权限
        */
        
        /**
        if (凭证校验成功) {
         [[MLIAPManager sharedManager] finishTransaction];
        }
        */
    }
}

- (void)failedPurchaseWithError:(NSString *)errorDescripiton {
    NSLog(@"购买失败");
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"失败" message:errorDescripiton delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
    [alert show];
}
-(void)requestData:(NSString *)string {
    
    NSString *urlStr = @"https://sandbox.iTunes.Apple.com/verifyReceipt";
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //创建request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[NSString stringWithFormat:@"receipt-data=%@",string] dataUsingEncoding:NSUTF8StringEncoding];
    
    //创建NSURLSession
    NSURLSession *session = [NSURLSession sharedSession];
    
    //创建任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSLog(@"%@",dict);
    }];
    
    //开始任务
    [task resume];
}
@end
