//
//  InAppPurchasePlugin.m
//  InAppPurchase
//
//  Created by Ed @ Work on 2017-03-08.
//  Copyright © 2017 RosterBot Inc. All rights reserved.
//

#import "InAppPurchasePlugin.h"
#import "InAppPurchasePluginPaymentQueueObserver.h"

@interface InAppPurchasePlugin ()

@property (nonatomic) NSMutableArray<NSString *> *updatedTransactionCallbackIds;
@property (nonatomic) NSString *productsRequestCallbackId;
@property (nonatomic) NSString *refreshReceiptCallbackId;

@end

@implementation InAppPurchasePlugin

@synthesize updatedTransactionCallbackIds;
@synthesize productsRequestCallbackId;
@synthesize refreshReceiptCallbackId;

- (void)pluginInitialize
{
    // not sure if I should be calling [super] here because I don't want a future release of cordova to uncomment these in the parent.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPause)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onResume)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];

    self.updatedTransactionCallbackIds = [[NSMutableArray alloc] init];
}

- (void)onAppTerminate
{
    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] stopObservingQueue];
}

- (void) onPause
{
    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] stopObservingQueue];
}

- (void) onResume
{
    if(self.updatedTransactionCallbackIds.count > 0)
    {
        [[InAppPurchasePluginPaymentQueueObserver sharedObserver] startObservingQueue];
    }
}

- (void)attachCallbackToListenForUpdatedTransactions:(CDVInvokedUrlCommand *)command
{
    [self.updatedTransactionCallbackIds addObject:command.callbackId];

    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] registerDelegate:self];

    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] startObservingQueue];
}

-(void)stopListeningForUpdatedTransactions:(CDVInvokedUrlCommand *)command
{
    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] stopObservingQueue];

    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] removeDelegate:self];

    for(NSString *callbackId in self.updatedTransactionCallbackIds)
    {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT]
                                                                      callbackId:callbackId];
    }

    [self.updatedTransactionCallbackIds removeAllObjects];
}

-(void)didReceiveUpdatedTransaction:(SKPaymentTransaction *)transaction onQueue:(SKPaymentQueue *)queue
{
        CDVPluginResult *result =
                        [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                      messageAsDictionary:[self buildPluginResultDictionaryForTransaction:transaction]];

        [result setKeepCallbackAsBool:YES];

        for(NSString *callbackId in self.updatedTransactionCallbackIds)
        {
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSMutableArray *formattedProducts = [[NSMutableArray alloc] initWithCapacity:response.products.count];
    for(SKProduct *product in response.products)
    {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *formattedPriceString = [numberFormatter stringFromNumber:product.price];

        [formattedProducts addObject:@{
                                       @"description": product.localizedDescription,
                                       @"title": product.localizedTitle,
                                       @"price": formattedPriceString,
                                       @"productId": product.productIdentifier
                                       }];
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                              messageAsArray:formattedProducts]
                                callbackId:self.productsRequestCallbackId];

    self.productsRequestCallbackId = nil;
}

- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"Request did finish?, %@", request);

    if([request isKindOfClass:[SKReceiptRefreshRequest class]])
    {
        NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];

        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                 messageAsString:[receiptData base64EncodedStringWithOptions:0]]
                                                                      callbackId:self.refreshReceiptCallbackId];

        self.refreshReceiptCallbackId = nil;
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Request did error?, %@", request);

    if([request isKindOfClass:[SKReceiptRefreshRequest class]])
    {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR]
                                    callbackId:self.refreshReceiptCallbackId];

        self.refreshReceiptCallbackId = nil;
    }
}

-(NSDictionary *)buildPluginResultDictionaryForTransaction:(SKPaymentTransaction *)transaction
{
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];

    NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];

    return @{
                @"transactionId": transaction.transactionIdentifier ? transaction.transactionIdentifier : [NSNull null],
                @"transactionState": [[NSNumber numberWithInteger:transaction.transactionState] stringValue],
                @"originalTransactionId": transaction.originalTransaction ? transaction.originalTransaction.transactionIdentifier : [NSNull null],
                @"transactionDate": transaction.transactionDate ? [formatter stringFromDate:transaction.transactionDate] : [NSNull null],
                @"transactionProductId": transaction.payment.productIdentifier,
                @"username": transaction.payment.applicationUsername ? transaction.payment.applicationUsername : [NSNull null],
                @"transactionQuantity": [[NSNumber numberWithInteger:transaction.payment.quantity] stringValue],
                @"latestReceiptData": [receiptData base64EncodedStringWithOptions:0] ? [receiptData base64EncodedStringWithOptions:0] : [NSNull null]
             };
}

-(void)getAvailableProducts:(CDVInvokedUrlCommand *)command
{
    NSArray *requestedProductIds = [command argumentAtIndex:0 withDefault:[NSArray array]];

    self.productsRequestCallbackId = command.callbackId;

    SKProductsRequest *request = [[SKProductsRequest alloc]
                                  initWithProductIdentifiers:[NSSet setWithArray:requestedProductIds]];

    request.delegate = self;

    [request start];
}

-(void)purchaseProduct:(CDVInvokedUrlCommand *)command
{
    NSString *productId = [command argumentAtIndex:0 withDefault:nil];

    CDVPluginResult *result = nil;

    if(![InAppPurchasePluginPaymentQueueObserver sharedObserver].isObserving)
    {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                   messageAsString:@"you cannot initiate a purchase without first observing the queue."];
    }
    else if(!productId)
    {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                   messageAsString:@"a product identifer is necessary to make a purchase."];
    }
    else
    {
        SKMutablePayment *payment = [[SKMutablePayment alloc] init];

        payment.productIdentifier = productId;
        NSString *quantity = [command argumentAtIndex:1 withDefault:@"1"];
        payment.quantity = quantity.integerValue;
        payment.applicationUsername = [command argumentAtIndex:2 withDefault:nil];

        [[SKPaymentQueue defaultQueue] addPayment:payment];

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)restoreTransactions:(CDVInvokedUrlCommand *)command
{
    NSString *applicationUsername = [command argumentAtIndex:0];

    if(applicationUsername)
    {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:applicationUsername];
    }
    else
    {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
}

-(void)refreshReceipt:(CDVInvokedUrlCommand *)command
{
    self.refreshReceiptCallbackId = command.callbackId;

    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];

    request.delegate = self;

    [request start];
}

-(void)arePaymentsAvailable:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result =
    [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                  messageAsBool:[SKPaymentQueue canMakePayments]];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)finishTransaction:(CDVInvokedUrlCommand *)command
{
    NSString *transactionId = [command argumentAtIndex:0 withDefault:@""];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    for(SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions)
    {
        if([transaction.transactionIdentifier isEqualToString:transactionId])
        {
            if(transaction.transactionState == SKPaymentTransactionStatePurchasing)
            {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"transaction is in purchasing state and cannot be finished."];
            }
            else
            {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        }
    }

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)dealloc
{
    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] stopObservingQueue];
    [[InAppPurchasePluginPaymentQueueObserver sharedObserver] removeDelegate:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

@end
