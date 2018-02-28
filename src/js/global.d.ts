declare namespace InAppPurchase {

    function listenForTransactions(onTransaction: (transaction: IAPTransaction) => void): void;

    function stopListeningForTransactions(): void;

    function getAvailableProducts(productIdentifiers: string[]): Promise;

    function purchaseProduct(productIdentifier: string, quantity: number, username: string): Promise;

    function restoreTransactions(username: string): Promise;

    function refreshReceipt(): Promise;

    function arePaymentsAvailable(): Promise;

    function finishTransaction(transactionId: string): Promise;

    interface IAPTransaction {
        transactionId: string;
        transactionState: TransactionStates;
        originalTransactionId: string;
        transactionDate: string;
        transactionProductId: string;
        username?: string;
        transactionQuantity: string;
        latestReceiptData: string;
    }

    interface TransactionStates {
        Purchasing: number,
        Purchased: number,
        Failed: number,
        Restored: number,
        Deferred: number
    }
}
