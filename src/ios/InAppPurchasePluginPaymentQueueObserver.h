//
//  InAppPurchasePluginPaymentQueueObserver.h
//  InAppPurchase
//
//  Created by Ed @ Work on 2017-03-08.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol InAppPurchasePluginQueueDelegate

-(void)didReceiveUpdatedTransaction:(SKPaymentTransaction *)transaction
                            onQueue:(SKPaymentQueue *)queue;

@end

@interface InAppPurchasePluginPaymentQueueObserver : NSObject <SKPaymentTransactionObserver>

@property (nonatomic) BOOL isObserving;

+(instancetype)sharedObserver;

-(void)startObservingQueue;
-(void)stopObservingQueue;

-(void)registerDelegate:(id <InAppPurchasePluginQueueDelegate>)delegate;
-(void)removeDelegate:(id <InAppPurchasePluginQueueDelegate>)delegate;


@end
