//
//  InAppPurchasePlugin.h
//  InAppPurchase
//
//  Created by Ed @ Work on 2017-03-08.
//  Copyright © 2017 RosterBot Inc. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import <Cordova/CDVPlugin.h>
#import "InAppPurchasePluginPaymentQueueObserver.h"

@interface InAppPurchasePlugin : CDVPlugin <InAppPurchasePluginQueueDelegate,SKProductsRequestDelegate,SKRequestDelegate>

- (void)pluginInitialize;
- (void)onAppTerminate;
- (void)onResume;
- (void)onPause;


@end
