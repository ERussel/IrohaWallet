import Foundation
import CommonWallet
import RobinHood
import IrohaCommunication

enum NetworkOperationFactoryError: Error {
    case undefined
}

final class NetworkOperationFactory {
    let account: WalletAccountSettingsProtocol

    init(account: WalletAccountSettingsProtocol) {
        self.account = account
    }
}

extension NetworkOperationFactory: WalletNetworkOperationFactoryProtocol {
    func fetchBalanceOperation(_ assets: [IRAssetId]) -> BaseOperation<[BalanceData]?> {
        return ClosureOperation {
            return assets.map { BalanceData(identifier: $0.identifier(), balance: "100")}
        }
    }

    func fetchTransactionHistoryOperation(_ filter: WalletHistoryRequest, pagination: OffsetPagination) -> BaseOperation<AssetTransactionPageData?> {
        return ClosureOperation {
            return AssetTransactionPageData(transactions: [])
        }
    }

    func transferMetadataOperation(_ assetId: IRAssetId) -> BaseOperation<TransferMetaData?> {
        return ClosureOperation {
            return nil
        }
    }

    func transferOperation(_ info: TransferInfo) -> BaseOperation<Void> {
        return ClosureOperation {}
    }

    func searchOperation(_ searchString: String) -> BaseOperation<[SearchData]?> {
        return ClosureOperation { return [] }
    }

    func contactsOperation() -> BaseOperation<[SearchData]?> {
        return ClosureOperation { return [] }
    }

    func withdrawalMetadataOperation(_ info: WithdrawMetadataInfo) -> BaseOperation<WithdrawMetaData?> {
        return ClosureOperation { return nil }
    }

    func withdrawOperation(_ info: WithdrawInfo) -> BaseOperation<Void> {
        return ClosureOperation {}
    }


}
