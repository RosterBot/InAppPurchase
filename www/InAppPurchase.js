'use strict';
var exec = require('cordova/exec');

var TransactionStatePurchasing = 0,    // Transaction is being added to the server queue.

    TransactionStatePurchased  = 1,    // Transaction is in queue, user has been charged.  Client should complete the
                                       // transaction.

    TransactionStateFailed     = 2,    // Transaction was cancelled or failed before being added to the server
                                       // queue.

    TransactionStateRestored   = 3,    // Transaction was restored from user's purchase history.  Client should
                                       // complete the transaction.

    TransactionStateDeferred   = 4


function listenForTransactions(onTransaction)
{
    exec(onTransaction, function ()
    {
    }, "InAppPurchase", "attachCallbackToListenForUpdatedTransactions");
}

//attachCallbackToListenForUpdatedTransactions

function stopListeningForTransactions()
{
    exec(function ()
         {
         }, function ()
         {
         }, "InAppPurchase", "stopListeningForUpdatedTransactions");
}

//stopListeningForUpdatedTransactions

function getAvailableProducts(productIdentifiers)
{
    return new Promise(function (resolve, reject)
    {
        if (productIdentifiers.constructor === Array && productIdentifiers.length > 0)
        {
            exec(resolve, reject, "InAppPurchase", "getAvailableProducts", [productIdentifiers]);
        }
        else
        {
            reject("you need to specify an array of at least one product id.");
        }
    });

}

//getAvailableProducts


function purchaseProduct(productIdentifier, quantity, username)
{
    return new Promise(function (resolve, reject)
    {
        if (typeof productIdentifier === 'string' || productIdentifier instanceof String)
        {
            exec(resolve,
                 reject,
                 "InAppPurchase",
                 "purchaseProduct",
                 [productIdentifier, quantity, username]);
        }
        else
        {
            reject("you need to specify a product id.");
        }
    });
}


//purchaseProduct

function restoreTransactions(username)
{
    return new Promise(function (resolve, reject)
    {
        exec(resolve, reject, "InAppPurchase", "restoreTransactions", [username]);
    });
}

//restoreTransactions

function refreshReceipt()
{
    return new Promise(function (resolve, reject)
    {
        exec(resolve, reject, "InAppPurchase", "refreshReceipt");
    })
}

//refreshReceipt

function arePaymentsAvailable()
{
    return new Promise(function (resolve, reject)
    {
        exec(resolve, reject, "InAppPurchase", "arePaymentsAvailable");
    });
}

//arePaymentsAvailable

function finishTransaction(transactionId)
{
    return new Promise(function(resolve, reject)
    {
        if (typeof transactionId === 'string' || transactionId instanceof String)
        {
            exec(resolve, reject, "InAppPurchase", "finishTransaction", [transactionId]);
        }
        else
        {
            reject("you need to specify a transaction id.");
        }
    });
}

//finishTransaction


exports.finishTransaction                   = finishTransaction;
exports.listenForTransactions               = listenForTransactions;
exports.arePaymentsAvailable                = arePaymentsAvailable;
exports.refreshReceipt                      = refreshReceipt;
exports.restoreTransactions                 = restoreTransactions;
exports.purchaseProduct                     = purchaseProduct;
exports.getAvailableProducts                = getAvailableProducts;
exports.stopListeningForUpdatedTransactions = stopListeningForTransactions;

exports.TransactionStates = {
    Purchasing: TransactionStatePurchasing,
    Purchased:  TransactionStatePurchased,
    Failed:     TransactionStateFailed,
    Restored:   TransactionStateRestored,
    Deferred:   TransactionStateDeferred
};
