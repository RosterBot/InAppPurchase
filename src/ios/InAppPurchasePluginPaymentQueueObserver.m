//
//  InAppPurchasePluginPaymentQueueObserver.m
//  InAppPurchase
//
//  Created by Ed @ Work on 2017-03-08.
//
//

#import "InAppPurchasePluginPaymentQueueObserver.h"

@interface InAppPurchasePluginPaymentQueueObserver ()

@property (nonatomic) NSMutableArray <id<InAppPurchasePluginQueueDelegate>> *pluginDelegates;

@end

@implementation InAppPurchasePluginPaymentQueueObserver

@synthesize isObserving;
@synthesize pluginDelegates = _pluginDelegates;

+(instancetype)sharedObserver
{
    static InAppPurchasePluginPaymentQueueObserver *sharedObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObserver = [[self alloc] init];
        sharedObserver.isObserving = NO;
    });
    return sharedObserver;
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for(SKPaymentTransaction *transaction in transactions)
    {
        for(id <InAppPurchasePluginQueueDelegate> delegate in self.pluginDelegates)
        {
            [delegate didReceiveUpdatedTransaction:transaction onQueue:queue];
        }
    }
}

-(void)startObservingQueue
{
    if (!self.isObserving)
    {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.isObserving = YES;
    }
}

-(void)stopObservingQueue
{
    if (self.isObserving)
    {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
        self.isObserving = NO;
    }
}


-(void)registerDelegate:(id <InAppPurchasePluginQueueDelegate>)delegate
{
    if(![self.pluginDelegates containsObject:delegate])
    {
        [self.pluginDelegates addObject:delegate];
    }
}

-(void)removeDelegate:(id <InAppPurchasePluginQueueDelegate>)delegate
{
    if([self.pluginDelegates containsObject:delegate])
    {
        [self.pluginDelegates removeObject:delegate];
    }
}

-(NSMutableArray *)pluginDelegates
{
    if(!_pluginDelegates)
    {
        self.pluginDelegates = [[NSMutableArray alloc] init];
    }
    return _pluginDelegates;
}

@end
